%% TMS 데이터와 시뮬레이션 데이터 비교 플로팅 스크립트
% 이 스크립트는 사용자가 선택한 TMS 데이터와 시뮬레이션 결과를 불러와
% 압력 및 추력 그래프를 나란히 플로팅하여 비교합니다.

clear; clc; close all;

%% 1. 데이터 파일 경로 설정 및 사용자 선택
fprintf('TMS 데이터와 시뮬레이션 데이터를 비교합니다.\n');

% 데이터 폴더 경로 설정 (상대 경로 사용)
tms_data_dir = fullfile('TMS_Data', 'DATA_MAT');
sim_data_dir = 'Mat_Data';

% --- TMS 데이터 파일 선택 ---
fprintf('1. 비교할 TMS 데이터 파일을 선택해주세요...\n');
[tms_file, tms_path] = uigetfile(fullfile(tms_data_dir, '*.mat'), 'TMS 데이터 파일 선택');

% 사용자가 선택을 취소한 경우 스크립트 종료
if isequal(tms_file, 0)
    fprintf('파일 선택이 취소되었습니다. 스크립트를 종료합니다.\n');
    return;
end
tms_full_path = fullfile(tms_path, tms_file);
fprintf('  -> 선택된 TMS 파일: %s\n', tms_full_path);

% --- 시뮬레이션 데이터 파일 선택 ---
fprintf('2. 비교할 시뮬레이션 데이터 파일들을 모두 선택해주세요 (추력, 탱크압, 인젝터압, 연소압)...\n');
[sim_files_list, sim_path] = uigetfile(fullfile(sim_data_dir, '*.mat'), ...
    '시뮬레이션 데이터 파일 선택 (Ctrl+클릭으로 다중 선택)', 'MultiSelect', 'on');

% 사용자가 선택을 취소한 경우 스크립트 종료
if isequal(sim_files_list, 0)
    fprintf('파일 선택이 취소되었습니다. 스크립트를 종료합니다.\n');
    return;
end

% 파일이 하나만 선택된 경우 cell array로 변환
if ~iscell(sim_files_list)
    sim_files_list = {sim_files_list};
end

fprintf('  -> %d개의 시뮬레이션 파일을 선택했습니다.\n', length(sim_files_list));


%% 2. 데이터 로딩
try
    % --- TMS 데이터 로드 ---
    fprintf('\nTMS 데이터를 로딩 중...\n');
    tms_data = load(tms_full_path);
    
    % Zoomed 데이터와 Full 데이터 모두 처리할 수 있도록 변수명 일반화
    if isfield(tms_data, 'Time_Pressure_Data')
        tms_pressure_table = tms_data.Time_Pressure_Data;
        tms_thrust_table = tms_data.Time_Thrust_Data;
    elseif isfield(tms_data, 'Zoomed_Time_Pressure_Data')
        tms_pressure_table = tms_data.Zoomed_Time_Pressure_Data;
        tms_thrust_table = tms_data.Zoomed_Time_Thrust_Data;
    else
        error('선택된 TMS 파일에서 압력 또는 추력 데이터를 찾을 수 없습니다.');
    end
    
    % --- 시뮬레이션 데이터 로드 ---
    fprintf('시뮬레이션 데이터를 로딩 중...\n');
    
    % 로드된 데이터를 저장할 구조체 초기화
    sim_data = struct(); 

    % 선택된 각 파일을 순회하며 데이터 유형 식별 및 로드
    for i = 1:length(sim_files_list)
        current_file = sim_files_list{i};
        full_path = fullfile(sim_path, current_file);
        
        if contains(current_file, 'Nozzle_Thrust')
            sim_data.thrust = load(full_path);
            fprintf('    - 추력 데이터 로드: %s\n', current_file);
        elseif contains(current_file, 'Tank_Pressure')
            sim_data.tank_p = load(full_path);
            fprintf('    - 탱크 압력 데이터 로드: %s\n', current_file);
        elseif contains(current_file, 'Injector_Pressure')
            sim_data.inj_p = load(full_path);
            fprintf('    - 인젝터 압력 데이터 로드: %s\n', current_file);
        elseif contains(current_file, 'Comb_Pressure')
            sim_data.comb_p = load(full_path);
            fprintf('    - 연소실 압력 데이터 로드: %s\n', current_file);
        else
            warning('알 수 없는 시뮬레이션 파일 유형입니다: %s', current_file);
        end
    end
    
    % 필수 데이터가 모두 로드되었는지 확인
    required_fields = {'thrust', 'tank_p', 'inj_p', 'comb_p'};
    missing_fields = {};
    for i = 1:length(required_fields)
        if ~isfield(sim_data, required_fields{i})
            missing_fields{end+1} = required_fields{i};
        end
    end

    if ~isempty(missing_fields)
        error('다음 필수 시뮬레이션 데이터가 선택되지 않았습니다: %s', strjoin(missing_fields, ', '));
    end

    % 시뮬레이션 기본 이름 추출 (그래프 제목용) - 첫 번째 파일에서 추출
    [~, sim_basename_full, ~] = fileparts(sim_files_list{1});
    sim_basename = erase(sim_basename_full, ...
        {'_output_Nozzle_Thrust_vs_Time', ...
         '_output_Tank_Pressure_vs_Time', ...
         '_output_Injector_Pressure_vs_Time', ...
         '_output_Comb_Pressure_vs_Time'});
    fprintf('  -> 시뮬레이션 기본 이름: %s\n', sim_basename);
    
    fprintf('모든 데이터를 성공적으로 로드했습니다.\n');

catch ME
    fprintf('데이터 로딩 중 오류가 발생했습니다: %s\n', ME.message);
    return;
end


%% 3. 비교 그래프 생성
fprintf('\n비교 그래프를 생성합니다...\n');

% 파일명에서 '_'를 공백으로 바꿔 제목으로 사용
[~, tms_name, ~] = fileparts(tms_file);
plot_title = sprintf('TMS(%s) vs. Simul(%s)', strrep(tms_name, '_', ' '), strrep(sim_basename, '_', ' '));

figure('Name', plot_title, 'NumberTitle', 'off');

% --- 압력 비교 플롯 ---
subplot(2, 1, 1);
hold on;
% --- TMS 데이터 플로팅 ---
plot(tms_pressure_table.Time_s, tms_pressure_table.Tank_Pressure_bar, 'DisplayName', 'TMS Tank P');
plot(tms_pressure_table.Time_s, tms_pressure_table.Injector_Pressure_bar, 'DisplayName', 'TMS Injector Upstream P');
plot(tms_pressure_table.Time_s, tms_pressure_table.Comb_Pressure_Fwd_bar, 'DisplayName', 'TMS Fwd Comb P');
plot(tms_pressure_table.Time_s, tms_pressure_table.Comb_Pressure_Aft_bar, 'DisplayName', 'TMS Aft Comb P');

% --- 시뮬레이션 데이터 플로팅 (Pa -> bar 변환) ---
plot(sim_data.tank_p.Time, sim_data.tank_p.Tank_Pressure / 1e5, '--', 'DisplayName', 'Simul Tank P');
plot(sim_data.comb_p.Time, sim_data.comb_p.Combustor_Pressure / 1e5, '--', 'DisplayName', 'Simul Comb P');
hold off;
title('Pressure Comparison');
xlabel('Time (s)');
ylabel('Pressure (bar)');
legend('Location', 'best');
grid on;

% --- 추력 비교 플롯 ---
subplot(2, 1, 2);
hold on;

% --- TMS Total Impulse Calculation & Plotting ---
tms_total_impulse = trapz(tms_thrust_table.Time_s, tms_thrust_table.Thrust_N);
tms_legend_str = sprintf('TMS Thrust (Total Impulse: %.2f Ns)', tms_total_impulse);
plot(tms_thrust_table.Time_s, tms_thrust_table.Thrust_N, 'DisplayName', tms_legend_str);

% --- Simulation Data Plotting ---
% .mat 파일 내의 변수 이름 불일치 문제 해결
if isfield(sim_data.thrust, 'thrust_vector') && isfield(sim_data.thrust, 'time_vector')
    % Gen_Nozzle_F_t.m에 의해 생성된 파일 형식: time_vector, thrust_vector
    sim_time_thrust = sim_data.thrust.time_vector;
    sim_thrust_values = sim_data.thrust.thrust_vector;
elseif isfield(sim_data.thrust, 'Thrust') && isfield(sim_data.thrust, 'Time')
    % GenMatResults.m에 의해 생성된 파일 형식: Time, Thrust
    sim_time_thrust = sim_data.thrust.Time;
    sim_thrust_values = sim_data.thrust.Thrust;
elseif isfield(sim_data.thrust, 'Thrust')
    % 시간 변수만 없을 경우, 공용 시간 축 사용
    sim_time_thrust = sim_data.tank_p.Time;
    sim_thrust_values = sim_data.thrust.Thrust;
    fprintf('참고: 시뮬레이션 추력 파일에 "Time" 변수가 없어 다른 데이터의 시간 축을 사용합니다.\n');
else
    error('선택된 시뮬레이션 추력 파일에서 "thrust_vector" 또는 "Thrust" 변수를 찾을 수 없습니다.');
end

% --- Simulation Total Impulse Calculation & Plotting ---
sim_total_impulse = trapz(sim_time_thrust, sim_thrust_values);
sim_legend_str = sprintf('Simul Thrust (Total Impulse: %.2f Ns)', sim_total_impulse);
plot(sim_time_thrust, sim_thrust_values, '--', 'DisplayName', sim_legend_str);

hold off;
title('Thrust Comparison');
xlabel('Time (s)');
ylabel('Thrust (N)');
legend('Location', 'best');
grid on;

% 전체 플롯 제목 설정
sgtitle(plot_title);

fprintf('그래프 생성이 완료되었습니다.\n');

