%% Cold Flow TMS 데이터와 시뮬레이션 데이터 비교 플로팅 스크립트
% 이 스크립트는 사용자가 선택한 수류 시험 TMS 데이터와 시뮬레이션 결과를
% 불러와 탱크 압력 그래프를 플로팅하여 비교합니다.

clear; clc; close all;

%% 1. 데이터 파일 경로 설정 및 사용자 선택
fprintf('수류 시험(Cold Flow) 데이터와 시뮬레이션 데이터를 비교합니다.\n');

% 데이터 폴더 경로 설정 (상대 경로 사용)
tms_data_dir = fullfile('TMS_Data', 'COLD_FLOW_MAT');
sim_data_dir = 'Mat_Data';

% --- TMS 데이터 파일 선택 ---
fprintf('1. 비교할 수류 시험(Cold Flow) TMS 데이터 파일을 선택해주세요...\n');
[tms_file, tms_path] = uigetfile(fullfile(tms_data_dir, '*.mat'), '수류 시험 TMS 데이터 파일 선택');

% 사용자가 선택을 취소한 경우 스크립트 종료
if isequal(tms_file, 0)
    fprintf('파일 선택이 취소되었습니다. 스크립트를 종료합니다.\n');
    return;
end
tms_full_path = fullfile(tms_path, tms_file);
fprintf('  -> 선택된 TMS 파일: %s\n', tms_full_path);

% --- 시뮬레이션 데이터 파일 선택 ---
fprintf('2. 비교할 시뮬레이션 탱크 압력(Tank Pressure) 데이터 파일을 선택해주세요...\n');
[sim_file, sim_path] = uigetfile(fullfile(sim_data_dir, '*_Tank_Pressure_vs_Time.mat'), '시뮬레이션 탱크 압력 파일 선택');

% 사용자가 선택을 취소한 경우 스크립트 종료
if isequal(sim_file, 0)
    fprintf('파일 선택이 취소되었습니다. 스크립트를 종료합니다.\n');
    return;
end
sim_full_path = fullfile(sim_path, sim_file);
fprintf('  -> 선택된 시뮬레이션 파일: %s\n', sim_full_path);


%% 2. 데이터 로딩
try
    % --- TMS 데이터 로드 ---
    fprintf('\nTMS 데이터를 로딩 중...\n');
    tms_data = load(tms_full_path);
    
    if isfield(tms_data, 'Time_Pressure_Data')
        tms_pressure_table = tms_data.Time_Pressure_Data;
    elseif isfield(tms_data, 'Zoomed_Time_Pressure_Data')
        tms_pressure_table = tms_data.Zoomed_Time_Pressure_Data;
    else
        error('선택된 TMS 파일에서 압력 데이터를 찾을 수 없습니다.');
    end
    
    % --- 시뮬레이션 데이터 로드 ---
    fprintf('시뮬레이션 데이터를 로딩 중...\n');
    sim_data = load(sim_full_path);

    if ~isfield(sim_data, 'Time') || ~isfield(sim_data, 'Tank_Pressure')
        error('선택된 시뮬레이션 파일에 "Time" 또는 "Tank_Pressure" 필드가 없습니다.');
    end
    
    fprintf('모든 데이터를 성공적으로 로드했습니다.\n');

catch ME
    fprintf('데이터 로딩 중 오류가 발생했습니다: %s\n', ME.message);
    return;
end


%% 3. 비교 그래프 생성
fprintf('\n비교 그래프를 생성합니다...\n');

% 파일명에서 '_'를 공백으로 바꿔 제목으로 사용
[~, tms_name, ~] = fileparts(tms_file);
[~, sim_name_full, ~] = fileparts(sim_file);
sim_basename = erase(sim_name_full, '_output_Tank_Pressure_vs_Time');
plot_title = sprintf('Cold Flow: TMS(%s) vs. Simul(%s)', strrep(tms_name, '_', ' '), strrep(sim_basename, '_', ' '));

figure('Name', plot_title, 'NumberTitle', 'off');

% --- 탱크 압력 비교 플롯 ---
hold on;
% TMS 데이터 플로팅
plot(tms_pressure_table.Time_s, tms_pressure_table.Tank_Pressure_bar, 'DisplayName', 'TMS Tank P');

% 시뮬레이션 데이터 플로팅 (Pa -> bar 변환)
plot(sim_data.Time, sim_data.Tank_Pressure / 1e5, '--', 'DisplayName', 'Simul Tank P');
hold off;

title('Tank Pressure Comparison');
xlabel('Time (s)');
ylabel('Pressure (bar)');
legend('Location', 'best');
grid on;

sgtitle(plot_title);

fprintf('그래프 생성이 완료되었습니다.\n');
