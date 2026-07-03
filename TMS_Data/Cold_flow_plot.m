%% Cold Flow Test 데이터 플로팅 스크립트
% 이 스크립트는 수류 테스트(.lvm) 파일을 읽어들여,
% 탱크 및 인젝터 압력 데이터를 플로팅하고 저장합니다.

clear; clc; close all;

%% 0. 사용자 설정
% 대기압 설정 (bar) - 측정된 게이지 압력을 절대압으로 변환하는데 사용됩니다.
atm_pressure_bar = 1.01325; 
fprintf('사용자 설정 대기압: %.5f bar\n\n', atm_pressure_bar);

%% 1. 모든 .lvm 데이터 파일 찾기 및 불러오기
% 캐시 파일을 사용하여 이전에 불러온 데이터를 재사용할 수 있습니다.

cache_file = 'Cold_Flow_Data_cache.mat'; % 수류 테스트용 캐시 파일
load_from_cache = false;

if exist(cache_file, 'file')
    reply = input('저장된 lvm 데이터 캐시를 사용하시겠습니까? [y/n]: ', 's');
    if isempty(reply) || lower(reply(1)) == 'y'
        fprintf('캐시 파일에서 데이터를 불러옵니다: %s\n', cache_file);
        load(cache_file, 'TMS_Data');
        if exist('TMS_Data', 'var')
            load_from_cache = true;
        else
            fprintf('캐시 파일에 TMS_Data 변수가 없습니다. 파일을 다시 읽습니다.\n');
        end
    else
        fprintf('캐시를 사용하지 않고 파일을 다시 읽습니다.\n');
    end
end

if ~load_from_cache
    % 현재 실행 중인 스크립트의 디렉토리 경로 가져오기
    try
        script_path = mfilename('fullpath');
        [script_dir, ~, ~] = fileparts(script_path);
    catch
        script_dir = pwd;
    end
    
    % 스크립트 디렉토리 및 하위 디렉토리에서 .lvm 파일을 재귀적으로 검색
    fprintf('다음 위치에서 .lvm 파일을 검색합니다: %s\n', script_dir);
    lvm_files = dir(fullfile(script_dir, '**', '*.lvm'));
    
    if isempty(lvm_files)
        error('.lvm 파일을 스크립트 디렉토리 또는 하위 디렉토리에서 찾을 수 없습니다.');
    end
    
    TMS_Data = struct();
    fprintf('%d개의 .lvm 파일을 찾았습니다. 처리 중...\n', length(lvm_files));
    
    for i = 1:length(lvm_files)
        file_info = lvm_files(i);
        if file_info.isdir, continue; end
        
        file_path = fullfile(file_info.folder, file_info.name);
        fprintf('파일 읽는 중: %s\n', file_path);
        
        [~, filename, ~] = fileparts(file_info.name);
        struct_field_name = matlab.lang.makeValidName(filename);
        
        try
            opts = detectImportOptions(file_path, 'FileType', 'text');
            opts.VariableNamingRule = 'preserve';
            data_table = readtable(file_path, opts);
            TMS_Data.(struct_field_name) = data_table;
            fprintf('  -> 데이터를 TMS_Data.%s 에 성공적으로 불러왔습니다.\n', struct_field_name);
        catch ME
            warning('파일을 자동으로 읽는 데 실패했습니다: %s\n. 오류: %s\n.', file_path, ME.message);
        end
    end

    fprintf('\n데이터를 캐시 파일에 저장합니다: %s\n', cache_file);
    save(cache_file, 'TMS_Data');
end

disp('데이터 로딩 완료. 다음 데이터 구조체가 생성되었습니다:');
disp(TMS_Data);

%% 2. 사용자 입력에 따라 특정 데이터셋 선택
data_fields = fieldnames(TMS_Data);
fprintf('\n사용 가능한 데이터셋:\n');
for k = 1:length(data_fields)
    fprintf('- %s\n', data_fields{k});
end

selected_field = '';
while isempty(selected_field)
    try
        userInput = input('\n불러올 데이터셋의 이름을 입력하세요: ', 's');
        if isfield(TMS_Data, userInput)
            selected_field = userInput;
            selected_data = TMS_Data.(selected_field);
            fprintf('\n"%s" 데이터를 "selected_data" 변수에 성공적으로 불러왔습니다.\n', selected_field);
            disp('선택된 데이터 (상위 5개 행):');
            disp(head(selected_data, 5));
        else
            fprintf('오류: "%s"는 유효한 데이터셋 이름이 아닙니다.\n', userInput);
        end
    catch ME
        fprintf('잘못된 입력입니다. 오류: %s\n', ME.message);
    end
end

% 각 센서에 대한 변환 계수 (y = a*x + b)
calibration_coeffs.Tank_P.a = 6112.32228;
calibration_coeffs.Tank_P.b = -24.32488;

%% 3. 초기 압력 오프셋 계산
fprintf('\n초기(0-1s) 압력 오프셋을 계산하여 보정합니다...\n');

% 0-1초 사이의 데이터 인덱스 찾기
offset_indices = selected_data{:, 1} >= 0 & selected_data{:, 1} <= 1;

if ~any(offset_indices)
    warning('오프셋 계산을 위한 0-1초 구간의 데이터가 없습니다. 보정을 건너뜁니다.');
    pressure_offset_tank = 0;
else
    % 탱크 압력의 초기 게이지 압력 평균값(오프셋) 계산
    pressure_offset_tank = mean(calibration_coeffs.Tank_P.a * selected_data{offset_indices, 2} + calibration_coeffs.Tank_P.b);
    fprintf('  - 탱크 압력 오프셋: %.4f bar\n', pressure_offset_tank);
end


%% 4. 데이터 변환 (전류 -> 물리 단위)

processed_data = table();
processed_data.Time_s = selected_data{:, 1};

gauge_p_tank = calibration_coeffs.Tank_P.a * selected_data{:, 2} + calibration_coeffs.Tank_P.b;
processed_data.Tank_Pressure_bar = (gauge_p_tank - pressure_offset_tank) + atm_pressure_bar;


fprintf('\n데이터를 보정된 절대압(bar)으로 변환했습니다.\n');
disp(head(processed_data, 5));

%% 3.5. 전체 데이터 저장
save_dir = 'TMS_Data/COLD_FLOW_MAT';
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
    fprintf('데이터 저장을 위한 폴더를 생성했습니다: %s\n', save_dir);
end

Time_Pressure_Data = processed_data(:, {'Time_s', 'Tank_Pressure_bar'});
full_duration_filename = fullfile(save_dir, [selected_field, '_cold_flow_full.mat']);
save(full_duration_filename, 'Time_Pressure_Data');
fprintf('전체 시간 데이터를 다음 파일에 저장했습니다:\n  %s\n', full_duration_filename);

%% 4. 처리된 데이터 플로팅
figure('Name', [selected_field, ' - Cold Flow Pressure']);
plot(processed_data.Time_s, processed_data.Tank_Pressure_bar);
title([strrep(selected_field, '_', ' '), ' - Tank Pressure vs. Time']);
xlabel('Time (s)');
ylabel('Pressure (bar)');
grid on;

%% 5. 사용자 지정 시간 범위 플로팅
while true
    reply = input('\n특정 시간 범위로 다시 플로팅하시겠습니까? [y/n]: ', 's');
    if isempty(reply) || lower(reply(1)) ~= 'y', break; end
    
    try
        start_time = str2double(input('시작 시간을 입력하세요 (초): ', 's'));
        end_time = str2double(input('종료 시간을 입력하세요 (초): ', 's'));
        
        if isnan(start_time) || isnan(end_time) || start_time >= end_time
            fprintf('오류: 유효한 시간 범위를 입력해주세요.\n');
            continue;
        end
        
        time_vec = processed_data.Time_s;
        idx = time_vec >= start_time & time_vec <= end_time;
        
        if ~any(idx)
            fprintf('오류: 지정된 시간 범위에 데이터가 없습니다.\n');
            continue;
        end
        
        zoomed_data = processed_data(idx, :);
        zoomed_data.Time_s = zoomed_data.Time_s - start_time;
        
        figure;
        plot(zoomed_data.Time_s, zoomed_data.Tank_Pressure_bar);
        
        title(sprintf('%s - Tank Pressure (Zoomed: %.2fs to %.2fs)', strrep(selected_field, '_', ' '), start_time, end_time));
        xlabel('Time (s)');
        ylabel('Pressure (bar)');
        grid on;
        
        fprintf('\n선택한 시간 범위 [%.2f s, %.2f s]에 대한 플롯을 생성했습니다.\n', start_time, end_time);
        
        Zoomed_Time_Pressure_Data = zoomed_data(:, {'Time_s', 'Tank_Pressure_bar'});
        filename_start = strrep(sprintf('%.2f', start_time), '.', 'p');
        filename_end = strrep(sprintf('%.2f', end_time), '.', 'p');
        zoomed_filename = fullfile(save_dir, sprintf('%s_cold_flow_zoomed_%sto%s.mat', selected_field, filename_start, filename_end));
        
        save(zoomed_filename, 'Zoomed_Time_Pressure_Data');
        fprintf('선택 시간 범위 데이터를 다음 파일에 저장했습니다:\n  %s\n', zoomed_filename);
        
    catch ME
        fprintf('잘못된 입력입니다. 오류: %s\n', ME.message);
    end
end
