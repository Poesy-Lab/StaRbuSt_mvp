% 이 스크립트는 사용자가 CSV 또는 Excel 파일을 선택하고, 플롯할 열을 선택하여,
% 결과 그래프를 PNG 파일로 저장하는 기능을 수행합니다.

% 시작하기 전에 작업 공간을 정리합니다.
clear; close all; clc;

% --- 1. 파일 선택 ---
% 스크립트가 위치한 경로를 기준으로 데이터 파일 경로를 설정합니다.
% 이렇게 하면 어느 위치에서 스크립트를 실행해도 경로 문제가 발생하지 않습니다.
try
    scriptFullPath = mfilename('fullpath');
    [scriptPath, ~, ~] = fileparts(scriptFullPath);
catch
    % mfilename이 라이브 에디터 등 일부 환경에서 오류를 발생시킬 수 있으므로
    % 현재 작업 디렉토리를 기준으로 예외 처리합니다.
    scriptPath = pwd;
end

fileDir = fullfile(scriptPath, 'TMS_data_plot');

% 데이터 디렉토리가 없는 경우 생성합니다.
if ~exist(fileDir, 'dir')
    mkdir(fileDir);
    fprintf('"%s" 디렉토리를 생성했습니다.\n', fileDir);
end

% 파일 선택 대화 상자를 엽니다.
[fileName, pathName] = uigetfile({'*.csv';'*.xlsx';'*.xls'}, '데이터 파일을 선택하세요', fileDir);

% 사용자가 '취소'를 누르거나 창을 닫았는지 확인합니다.
if isequal(fileName, 0)
    disp('파일 선택이 취소되었습니다. 스크립트를 종료합니다.');
    return;
else
    fullFilePath = fullfile(pathName, fileName);
    fprintf('선택된 파일: %s\n', fullFilePath);
end

% --- 2. 데이터 읽기 및 열 선택 ---
% 선택된 파일을 테이블 형식으로 읽어옵니다.
try
    opts = detectImportOptions(fullFilePath);
    % 변수 이름(열 이름)에 공백이나 특수문자가 있어도 그대로 사용하도록 설정합니다.
    opts.VariableNamingRule = 'preserve';
    dataTable = readtable(fullFilePath, opts);
catch ME
    error('파일을 읽는 중 오류가 발생했습니다: %s', ME.message);
end

% 테이블의 첫 행(헤더)에서 변수명(열 이름)을 가져옵니다.
variableNames = dataTable.Properties.VariableNames;

% 사용자에게 X축으로 사용할 변수를 선택하도록 요청합니다.
[x_index, x_ok] = listdlg('PromptString', 'X축으로 사용할 변수를 선택하세요:', ...
                         'SelectionMode', 'single', ...
                         'ListString', variableNames, ...
                         'Name', 'X축 선택');
% 사용자가 선택을 취소했는지 확인합니다.
if ~x_ok
    disp('X축 선택이 취소되었습니다. 스크립트를 종료합니다.');
    return;
end
xVarName = variableNames{x_index};

% 사용자에게 Y축으로 사용할 변수(들)를 선택하도록 요청합니다.
[y_indices, y_ok] = listdlg('PromptString', 'Y축으로 사용할 변수를 선택하세요 (다중 선택 가능):', ...
                          'ListString', variableNames, ...
                          'Name', 'Y축 선택');
% 사용자가 선택을 취소했는지 확인합니다.
if ~y_ok
    disp('Y축 선택이 취소되었습니다. 스크립트를 종료합니다.');
    return;
end
yVarNames = variableNames(y_indices);

% 사용자로부터 그래프 제목을 입력받습니다.
prompt = {'그래프의 제목을 입력하세요:'};
dlgtitle = '그래프 제목 입력';
dims = [1 70];

% 제안할 기본 제목을 생성합니다.
if strcmp(xVarName, 'Time_s') && length(yVarNames) == 1 && strcmp(yVarNames{1}, 'Thrust_N')
    defaultTitle = sprintf('%s vs. %s (Performance Analysis)', yVarNames{1}, xVarName);
else
    defaultTitle = sprintf('%s vs. %s', strjoin(yVarNames, ', '), xVarName);
end
answer = inputdlg(prompt, dlgtitle, dims, {defaultTitle});

% 사용자가 '취소'를 눌렀는지 확인합니다.
if isempty(answer)
    disp('제목 입력이 취소되었습니다. 스크립트를 종료합니다.');
    return;
else
    plotTitle = answer{1};
end

% --- 3. 그래프 플롯, 분석 및 저장 ---
% 새로운 Figure 창을 생성합니다.
hFig = figure('Name', 'TMS Data Plot', 'NumberTitle', 'off');

% --- 4. 플롯 유형에 따른 분기 ---
% 선택된 변수가 Time_s와 Thrust_N인지 확인하여 성능 분석을 수행합니다.
if strcmp(xVarName, 'Time_s') && length(yVarNames) == 1 && strcmp(yVarNames{1}, 'Thrust_N')
    
    % --- 데이터 준비 및 분석 ---
    timeVec = dataTable.Time_s;
    thrustVec = dataTable.Thrust_N;
    
    % 0 미만의 추력 값은 계산에서 제외합니다 (센서 노이즈 등 제거).
    thrustVec(thrustVec < 0) = 0;
    
    [maxThrust, maxThrustIdx] = max(thrustVec);
    
    % --- Operating Time 재정의 ---
    % 시작: 추력이 처음으로 0보다 커지는 지점
    opStartIdx_candidates = find(thrustVec > 0, 1, 'first');
    if isempty(opStartIdx_candidates)
        disp('추력이 0보다 큰 구간이 없어 분석을 중단합니다.');
        % Figure 창을 닫고 스크립트 종료
        close(hFig);
        return;
    end
    opStartIdx = opStartIdx_candidates;

    % 종료: 최대 추력 이후 처음으로 3N 미만이 되는 지점
    opEndIdx_candidates = find(thrustVec(maxThrustIdx:end) < 3, 1, 'first');
    if isempty(opEndIdx_candidates)
        % 3N 미만으로 떨어지지 않으면 데이터의 끝을 사용
        opEndIdx = length(thrustVec);
        disp('경고: 추력이 최대치 이후 3N 미만으로 떨어지지 않았습니다. 데이터의 끝을 Operating Time 종료로 사용합니다.');
    else
        % 인덱스는 maxThrustIdx부터 시작했으므로 보정
        opEndIdx = maxThrustIdx + opEndIdx_candidates - 1;
    end
    
    % 플롯 및 계산에 사용할 데이터 범위
    plotRange = opStartIdx:opEndIdx;
    timeVec_op = timeVec(plotRange);
    thrustVec_op = thrustVec(plotRange);
    
    operatingTime = timeVec_op(end) - timeVec_op(1);
    
    % Operating Time 기준 성능 지표 계산
    opTimeTotalImpulse = trapz(timeVec_op, thrustVec_op);
    if operatingTime > 0
        opTimeAverageThrust = opTimeTotalImpulse / operatingTime;
    else
        opTimeAverageThrust = 0;
    end

    % --- Burn Time 계산 (기존 정의 유지, 전체 데이터 기준) ---
    threshold = 0.05 * maxThrust;
    burnIndices = find(thrustVec >= threshold);
    if isempty(burnIndices)
        disp('추력이 최대 추력의 5%에 도달하지 못해 Burn Time을 계산할 수 없습니다.');
        burnTime = 0; burnTimeTotalImpulse = 0; burnTimeAverageThrust = 0;
    else
        burnStartIdx = burnIndices(1);
        burnEndIdx = burnIndices(end);
        burnTime = timeVec(burnEndIdx) - timeVec(burnStartIdx);
        
        burnTimeIndicesForTrapz = burnStartIdx:burnEndIdx;
        burnTimeTotalImpulse = trapz(timeVec(burnTimeIndicesForTrapz), thrustVec(burnTimeIndicesForTrapz));
        if burnTime > 0
            burnTimeAverageThrust = burnTimeTotalImpulse / burnTime;
        else
            burnTimeAverageThrust = 0;
        end
    end

    % --- 비추력 계산 ---
    prompt = {'연소된 추진제 질량(kg)을 입력하세요:'};
    dlgtitle = 'Specific Impulse Calculation';
    dims = [1 50];
    definput = {'0.0'};
    answer = inputdlg(prompt, dlgtitle, dims, definput);
    
    specificImpulseStr = 'N/A';
    if ~isempty(answer)
        propellantMass = str2double(answer{1});
        if ~isnan(propellantMass) && propellantMass > 0
            g = 9.80665; % 표준 중력 가속도
            specificImpulse = opTimeTotalImpulse / (propellantMass * g);
            specificImpulseStr = sprintf('%.2f s', specificImpulse);
        else
            specificImpulseStr = 'N/A (유효하지 않은 질량)';
        end
    else
        specificImpulseStr = 'N/A (입력 취소됨)';
    end

    % --- 그래프 플롯 (잘린 데이터 기준) ---
    plot(timeVec_op, thrustVec_op, 'LineWidth', 1.5);
    grid on;
    xlabel(xVarName, 'Interpreter', 'none');
    ylabel(yVarNames{1}, 'Interpreter', 'none');
    title(plotTitle, 'Interpreter', 'none');
    xlim([timeVec_op(1), timeVec_op(end)]); % x축 범위를 operating time에 맞춤

    % --- 성능 지표 텍스트 생성 및 표시 ---
    textStr = {
        '--- Performance Analysis ---', ...
        sprintf('Maximum Thrust: %.2f N', maxThrust), ...
        '', ...
        '-- Burn Time Based --', ...
        sprintf('Burn Time: %.2f s', burnTime), ...
        sprintf('Total Impulse: %.2f Ns', burnTimeTotalImpulse), ...
        sprintf('Average Thrust: %.2f N', burnTimeAverageThrust), ...
        '', ...
        '-- Operating Time Based --', ...
        sprintf('Operating Time: %.2f s', operatingTime), ...
        sprintf('Total Impulse: %.2f Ns', opTimeTotalImpulse), ...
        sprintf('Average Thrust: %.2f N', opTimeAverageThrust), ...
        sprintf('Specific Impulse: %s', specificImpulseStr)
    };
    
    annotation('textbox', [0.65, 0.55, 0.25, 0.35], ...
               'String', textStr, 'EdgeColor', 'black', ...
               'BackgroundColor', 'white', 'FitBoxToText', 'on', ...
               'FontSize', 8, 'VerticalAlignment', 'top');

else
    % --- 일반 플롯 (Thrust 분석 외) ---
    plot(dataTable.(xVarName), dataTable{:, yVarNames}, 'LineWidth', 1.5);
    grid on;
    xlabel(xVarName, 'Interpreter', 'none');
    ylabel('값', 'Interpreter', 'none');
    title(plotTitle, 'Interpreter', 'none');
    
    if length(yVarNames) > 1
        legend(yVarNames, 'Interpreter', 'none', 'Location', 'best');
    end
end

% --- PNG 파일로 저장 ---
% 그래프를 저장할 경로를 설정합니다.
saveDir = fullfile(fileDir, 'plot_png');

% 저장할 디렉토리가 없으면 새로 생성합니다.
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

% 저장될 파일의 이름을 생성합니다. (예: '데이터파일명_plot_Y변수1&Y변수2_vs_X변수.png')
[~, baseFileName, ~] = fileparts(fileName);
plotFileName = matlab.lang.makeValidName(sprintf('%s_%s', baseFileName, plotTitle));
fullSavePath = fullfile(saveDir, [plotFileName, '.png']);

% 생성된 그래프를 PNG 파일로 저장합니다.
try
    saveas(hFig, fullSavePath);
    fprintf('그래프가 다음 경로에 저장되었습니다: %s\n', fullSavePath);
catch ME
    error('그래프를 저장하는 중 오류가 발생했습니다: %s', ME.message);
end
