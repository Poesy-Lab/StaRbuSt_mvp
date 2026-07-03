%% TMS 데이터 플로팅 스크립트
% 이 스크립트는 현재 폴더 및 하위 폴더에 있는 모든 .lvm 파일을 읽어들여,
% 플로팅을 위해 구조화된 형식으로 데이터를 처리하고 저장합니다.

clear; clc; close all;

%% 0. 사용자 설정
% 대기압 설정 (bar) - 측정된 게이지 압력을 절대압으로 변환하는데 사용됩니다.
atm_pressure_bar = 1; 
fprintf('사용자 설정 대기압: %.5f bar\n\n', atm_pressure_bar);

%% 1. 모든 .lvm 데이터 파일 찾기 및 불러오기
% 캐시 파일을 사용하여 이전에 불러온 데이터를 재사용할 수 있습니다.

cache_file = 'TMS_Data_cache.mat';
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
        % 스크립트의 일부만 실행하거나 구버전 MATLAB에서 실행할 경우를 대비한 폴백
        script_dir = pwd;
    end
    
    % 스크립트 디렉토리 및 하위 디렉토리에서 .lvm 파일을 재귀적으로 검색
    fprintf('다음 위치에서 .lvm 파일을 검색합니다: %s\n', script_dir);
    lvm_files = dir(fullfile(script_dir, '**', '*.lvm'));
    
    % 파일이 발견되었는지 확인
    if isempty(lvm_files)
        error('.lvm 파일을 스크립트 디렉토리 또는 하위 디렉토리에서 찾을 수 없습니다. 파일 위치를 확인해주세요.');
    end
    
    % 모든 데이터를 저장할 구조체 생성
    TMS_Data = struct();
    
    fprintf('%d개의 .lvm 파일을 찾았습니다. 처리 중...\n', length(lvm_files));
    
    % 각 파일을 순회하며 처리
    for i = 1:length(lvm_files)
        file_info = lvm_files(i);
        
        % 디렉토리는 건너뛰기
        if file_info.isdir
            continue;
        end
        
        file_path = fullfile(file_info.folder, file_info.name);
        fprintf('파일 읽는 중: %s\n', file_path);
        
        % 파일 이름으로부터 유효한 MATLAB 변수 이름 생성
        [~, filename, ~] = fileparts(file_info.name);
        % 원본 파일 이름에는 '#', 공백 등 변수명으로 부적합한 문자가 있을 수 있습니다.
        % `makeValidName` 함수를 사용하여 이를 수정합니다.
        struct_field_name = matlab.lang.makeValidName(filename);
    
        % .lvm 파일 읽기. 일반적으로 탭으로 구분된 헤더가 있는 텍스트 파일입니다.
        % `readtable`을 사용하여 자동으로 형식 감지를 시도합니다.
        try
            % 'FileType', 'text' 옵션과 함께 `readtable`을 사용하여 파일 읽기
            % 이 함수는 구분 기호와 헤더 라인을 자동으로 감지할 수 있습니다.
            opts = detectImportOptions(file_path, 'FileType', 'text');
            opts.VariableNamingRule = 'preserve'; % 변수 이름(열 이름)을 원본 그대로 유지
            data_table = readtable(file_path, opts);
            
            % 생성된 필드 이름을 사용하여 주 구조체에 테이블 저장
            TMS_Data.(struct_field_name) = data_table;
            fprintf('  -> 데이터를 TMS_Data.%s 에 성공적으로 불러왔습니다.\n', struct_field_name);
            
        catch ME
            warning('파일을 자동으로 읽는 데 실패했습니다: %s\n. 오류: %s\n. 파일 형식을 확인해주세요.', file_path, ME.message);
        end
    end

    % 처리 후 캐시 파일에 저장
    fprintf('\n데이터를 캐시 파일에 저장합니다: %s\n', cache_file);
    save(cache_file, 'TMS_Data');
end

% 불러온 데이터 구조체 출력
disp('데이터 로딩 완료. 다음 데이터 구조체가 생성되었습니다:');
disp(TMS_Data);

%% 2. 사용자 입력에 따라 특정 데이터셋 선택

% 사용 가능한 데이터셋 목록 가져오기
data_fields = fieldnames(TMS_Data);

% 사용자에게 선택 가능한 데이터셋 목록 표시
fprintf('\n사용 가능한 데이터셋:\n');
for k = 1:length(data_fields)
    fprintf('- %s\n', data_fields{k});
end

% 사용자로부터 데이터셋 이름 입력받기
selected_field = '';
selected_data = [];
while isempty(selected_field)
    try
        userInput = input('\n불러올 데이터셋의 이름을 입력하세요 (예: x25_07_10_hot_fire): ', 's');
        
        % 입력된 이름이 구조체에 있는지 확인
        if isfield(TMS_Data, userInput)
            selected_field = userInput;
            selected_data = TMS_Data.(selected_field);
            fprintf('\n"%s" 데이터를 "selected_data" 변수에 성공적으로 불러왔습니다.\n', selected_field);
            
            % 선택된 데이터 테이블의 처음 몇 줄 표시
            disp('선택된 데이터 (상위 5개 행):');
            disp(head(selected_data, 5));

        else
            fprintf('오류: "%s"는 유효한 데이터셋 이름이 아닙니다. 다시 시도해주세요.\n', userInput);
        end
    catch ME
        fprintf('잘못된 입력입니다. 다시 시도해주세요. 오류: %s\n', ME.message);
    end
end


%% 다음 단계: 'selected_data' 변수를 사용하여 데이터 분석 및 플로팅
% 예:
% disp('선택된 데이터의 열:');
% disp(selected_data.Properties.VariableNames);
% figure; % 새 그림 창 열기
% plot(selected_data{:,1}, selected_data{:,2}); % 첫 번째 열을 x, 두 번째 열을 y로 가정
% title(['Plot for ', strrep(selected_field, '_', ' ')]);
% xlabel(selected_data.Properties.VariableNames{1});
% ylabel(selected_data.Properties.VariableNames{2});
% grid on;

% 각 센서에 대한 변환 계수 (y = a*x + b)
% y: 물리 단위 (bar 또는 kgf), x: 측정 단위 (A)
% !!! 여기에 실제 센서 교정 값을 입력해야 합니다. !!!
calibration_coeffs.Tank_P.a = 6112.32228;       % 탱크 압력 'a' 계수
calibration_coeffs.Tank_P.b = -24.32488;       % 탱크 압력 'b' 계수

% calibration_coeffs.Inj_P.a = 3116.94105;        % 인젝터 압력 'a' 계수 - 사용 안 함
% calibration_coeffs.Inj_P.b = -12.61502;        % 인젝터 압력 'b' 계수 - 사용 안 함

calibration_coeffs.Comb_P_Fwd.a = 3139.23807;   % 전방 연소실 압력 'a' 계수
calibration_coeffs.Comb_P_Fwd.b = -12.51622;   % 전방 연소실 압력 'b' 계수

calibration_coeffs.Comb_P_Aft.a = 3144.16133;   % 후방 연소실 압력 'a' 계수
calibration_coeffs.Comb_P_Aft.b = -12.48161;   % 후방 연소실 압력 'b' 계수

calibration_coeffs.Thrust.a = 6185.4965;       % 추력 'a' 계수 (A to kgf)
calibration_coeffs.Thrust.b = -24.93751;       % 추력 'b' 계수 (A to kgf)

%% 3. 초기 압력 오프셋 계산
fprintf('\n초기(0-1s) 압력 오프셋을 계산하여 보정합니다...\n');

% 0-1초 사이의 데이터 인덱스 찾기
offset_indices = selected_data{:, 1} >= 0 & selected_data{:, 1} <= 1;

if ~any(offset_indices)
    warning('오프셋 계산을 위한 0-1초 구간의 데이터가 없습니다. 보정을 건너뜁니다.');
    pressure_offsets.Tank_P = 0;
    pressure_offsets.Comb_P_Fwd = 0;
    pressure_offsets.Comb_P_Aft = 0;
else
    % 각 센서별 초기 게이지 압력의 평균값(오프셋) 계산
    pressure_offsets.Tank_P = mean(calibration_coeffs.Tank_P.a * selected_data{offset_indices, 2} + calibration_coeffs.Tank_P.b);
    pressure_offsets.Comb_P_Fwd = mean(calibration_coeffs.Comb_P_Fwd.a * selected_data{offset_indices, 3} + calibration_coeffs.Comb_P_Fwd.b);
    pressure_offsets.Comb_P_Aft = mean(calibration_coeffs.Comb_P_Aft.a * selected_data{offset_indices, 4} + calibration_coeffs.Comb_P_Aft.b);

    fprintf('  - 탱크 압력 오프셋: %.4f bar\n', pressure_offsets.Tank_P);
    fprintf('  - 전방 연소실 압력 오프셋: %.4f bar\n', pressure_offsets.Comb_P_Fwd);
    fprintf('  - 후방 연소실 압력 오프셋: %.4f bar\n', pressure_offsets.Comb_P_Aft);
end


%% 4. 데이터 변환 (전류 -> 물리 단위)

% kgf를 N으로 변환하기 위한 상수 (중력가속도)
g = 9.80665;

% 원본 데이터를 복사하여 처리된 데이터를 저장할 새 테이블 생성
processed_data = table();
processed_data.Time_s = selected_data{:, 1};

% 원본 테이블의 열 이름 가져오기 (존재한다고 가정)
original_varnames = selected_data.Properties.VariableNames;

% 각 열에 변환 적용 및 새 열 이름 지정
% 2열: 탱크 내부압 (bar)
gauge_p_tank = calibration_coeffs.Tank_P.a * selected_data{:, 2} + calibration_coeffs.Tank_P.b;
processed_data.Tank_Pressure_bar = gauge_p_tank; % 탱크 압력은 오프셋 보정 없이 게이지 압력 사용

% 3열: 전방 연소실 압력 (bar)
gauge_p_comb_fwd = calibration_coeffs.Comb_P_Fwd.a * selected_data{:, 3} + calibration_coeffs.Comb_P_Fwd.b;
processed_data.Comb_Pressure_Fwd_bar = gauge_p_comb_fwd - pressure_offsets.Comb_P_Fwd; % 오프셋 보정된 게이지 압력 사용

% 4열: 후방 연소실 압력 (bar)
gauge_p_comb_aft = calibration_coeffs.Comb_P_Aft.a * selected_data{:, 4} + calibration_coeffs.Comb_P_Aft.b;
processed_data.Comb_Pressure_Aft_bar = gauge_p_comb_aft - pressure_offsets.Comb_P_Aft; % 오프셋 보정된 게이지 압력 사용

% 5열: 추력 (N)
% A -> kgf -> N 순으로 변환
thrust_kgf = calibration_coeffs.Thrust.a * selected_data{:, 5} + calibration_coeffs.Thrust.b;
processed_data.Thrust_N = thrust_kgf * g; % 추력 오프셋 보정 제거

fprintf('\n데이터를 물리 단위 (보정된 절대압 bar, N)로 변환하여 "processed_data" 변수에 저장했습니다.\n');
disp('처리된 데이터 (상위 5개 행):');
disp(head(processed_data, 5));


%% 4.5. 선택적 고급 추력 오프셋 보정
% 사용자가 원하는 경우, 두 단계에 걸쳐 추력 오프셋을 보정합니다.
% 1. 프리로드 오프셋: 연소 전 구간의 평균을 전체 데이터에서 빼서 0으로 맞춥니다.
% 2. 연소 후 오프셋: 연소 후 구간의 잔류 추력을 평균내어, 연소 시작점 이후의 데이터에서만 뺍니다.
apply_advanced_offset = false;
reply = input('\n고급 추력 오프셋 보정을 적용하시겠습니까? [y/n]: ', 's');
if ~isempty(reply) && lower(reply(1)) == 'y'
    apply_advanced_offset = true;
end

if apply_advanced_offset
    try
        % --- 1단계: 프리로드 오프셋 ---
        preload_end_time_str = input('1단계 - 프리로드 기간의 종료 시간을 입력하세요 (초): ', 's');
        preload_end_time = str2double(preload_end_time_str);
        
        if isnan(preload_end_time) || preload_end_time <= 0
            error('유효하지 않은 시간입니다. 보정을 중단합니다.');
        end
        
        preload_indices = processed_data.Time_s >= 0 & processed_data.Time_s <= preload_end_time;
        if ~any(preload_indices)
            error('지정된 프리로드 기간에 데이터가 없습니다.');
        end
        
        preload_offset = mean(processed_data.Thrust_N(preload_indices));
        processed_data.Thrust_N = processed_data.Thrust_N - preload_offset;
        fprintf('\n1단계 완료: 프리로드 오프셋(%.4f N)을 적용했습니다.\n', preload_offset);

        % --- 2단계: 연소 후 잔류 추력 오프셋 ---
        reply2 = input('2단계 - 연소 후 잔류 추력 오프셋을 적용하시겠습니까? [y/n]: ', 's');
        if ~isempty(reply2) && lower(reply2(1)) == 'y'
            ignition_time_str = input('  - 주 추력 시작 시간을 입력하세요 (초): ', 's');
            ignition_time = str2double(ignition_time_str);

            post_offset_start_time_str = input('  - 연소 후 오프셋 계산 시작 시간을 입력하세요 (초): ', 's');
            post_offset_start_time = str2double(post_offset_start_time_str);
            
            if isnan(ignition_time) || isnan(post_offset_start_time) || ignition_time >= post_offset_start_time
                error('시간 입력이 잘못되었습니다. 주 추력 시작 시간은 오프셋 계산 시작 시간보다 빨라야 합니다.');
            end

            % 1단계 오프셋이 적용된 데이터에서 잔류 추력 계산
            post_offset_indices = processed_data.Time_s >= post_offset_start_time;
            if ~any(post_offset_indices)
                error('지정된 연소 후 오프셋 계산 기간에 데이터가 없습니다.');
            end
            
            post_thrust_offset = mean(processed_data.Thrust_N(post_offset_indices));
            
            % 주 추력 시작 시간 이후의 데이터에만 2단계 오프셋 적용
            main_thrust_indices = processed_data.Time_s >= ignition_time;
            processed_data.Thrust_N(main_thrust_indices) = processed_data.Thrust_N(main_thrust_indices) - post_thrust_offset;
            
            fprintf('2단계 완료: 연소 후 잔류 추력 오프셋(%.4f N)을 적용했습니다.\n', post_thrust_offset);

            % --- 3단계: 레일 마찰력 보정 ---
            friction_correction_factor = 1.1;
            fprintf('\n3단계: 주 연소 구간 추력에 마찰력 보정계수(%.1f)를 적용합니다...\n', friction_correction_factor);

            % 주 연소 구간 인덱스 (주 추력 시작 시간부터 연소 후 오프셋 계산 시작 시간 전까지)
            main_combustion_indices = processed_data.Time_s >= ignition_time & processed_data.Time_s < post_offset_start_time;
            
            % 해당 구간 추력에 보정계수 적용
            processed_data.Thrust_N(main_combustion_indices) = processed_data.Thrust_N(main_combustion_indices) * friction_correction_factor;
            
            fprintf('3단계 완료: 마찰력 보정계수를 적용했습니다.\n');
        end
        
        disp('최종 보정 후 데이터 (상위 5개 행):');
        disp(head(processed_data, 5));
        
    catch ME
        warning('TMS:offsetError', '고급 추력 오프셋 보정 중 오류가 발생했습니다: %s', ME.message);
    end
end


%% 3.5. 전체 데이터 저장
% 처리된 전체 시간 데이터를 .mat 파일로 저장합니다.
save_dir = 'TMS_Data/DATA_MAT';
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
    fprintf('데이터 저장을 위한 폴더를 생성했습니다: %s\n', save_dir);
end

% 압력 및 추력 데이터를 별도의 테이블로 준비
Time_Pressure_Data = processed_data(:, {'Time_s', 'Tank_Pressure_bar', 'Comb_Pressure_Fwd_bar', 'Comb_Pressure_Aft_bar'});
Time_Thrust_Data = processed_data(:, {'Time_s', 'Thrust_N'});

% 파일 저장
full_duration_filename = fullfile(save_dir, [selected_field, '_full_duration.mat']);
save(full_duration_filename, 'Time_Pressure_Data', 'Time_Thrust_Data');
fprintf('전체 시간 데이터를 다음 파일에 저장했습니다:\n  %s\n', full_duration_filename);


%% 4. 처리된 데이터 플로팅
% 예: 시간에 따른 추력 및 압력 플롯
figure;

% 모든 압력 데이터를 한 번에 플로팅
subplot(2, 1, 1);
hold on;
plot(processed_data.Time_s, processed_data.Tank_Pressure_bar, 'DisplayName', 'Tank Pressure');
plot(processed_data.Time_s, processed_data.Comb_Pressure_Fwd_bar, 'DisplayName', 'Comb. Pressure (Fwd)');
plot(processed_data.Time_s, processed_data.Comb_Pressure_Aft_bar, 'DisplayName', 'Comb. Pressure (Aft)');
hold off;
title([strrep(selected_field, '_', ' '), ' - Pressures vs. Time']);
xlabel('Time (s)');
ylabel('Pressure (bar)');
legend;
grid on;

% 추력 데이터 플로팅
subplot(2, 1, 2);
plot(processed_data.Time_s, processed_data.Thrust_N);
title([strrep(selected_field, '_', ' '), ' - Thrust vs. Time']);
xlabel('Time (s)');
ylabel('Thrust (N)');
grid on;

%% 5. 사용자 지정 시간 범위 플로팅
while true
    reply = input('\n특정 시간 범위로 다시 플로팅하시겠습니까? [y/n]: ', 's');
    if isempty(reply) || lower(reply(1)) ~= 'y'
        break;
    end
    
    % 사용자로부터 시간 범위 입력받기
    try
        start_time_str = input('시작 시간을 입력하세요 (초): ', 's');
        end_time_str = input('종료 시간을 입력하세요 (초): ', 's');
        
        start_time = str2double(start_time_str);
        end_time = str2double(end_time_str);
        
        % 입력값 검증
        if isnan(start_time) || isnan(end_time) || start_time >= end_time
            fprintf('오류: 유효한 시간 범위를 입력해주세요. 시작 시간은 종료 시간보다 작아야 합니다.\n');
            continue;
        end
        
        % 해당 시간 범위의 데이터 필터링
        time_vec = processed_data.Time_s;
        idx = time_vec >= start_time & time_vec <= end_time;
        
        if ~any(idx)
            fprintf('오류: 지정된 시간 범위에 데이터가 없습니다. 전체 시간 범위는 %.2f초부터 %.2f초까지입니다.\n', time_vec(1), time_vec(end));
            continue;
        end
        
        zoomed_data = processed_data(idx, :);
        
        % 시간 축을 0부터 시작하도록 조정
        zoomed_data.Time_s = zoomed_data.Time_s - start_time;
        
        % 새 창에 플로팅
        figure;
        
        % 압력 데이터 플로팅
        subplot(2, 1, 1);
        hold on;
        plot(zoomed_data.Time_s, zoomed_data.Tank_Pressure_bar, 'DisplayName', 'Tank Pressure');
        plot(zoomed_data.Time_s, zoomed_data.Comb_Pressure_Fwd_bar, 'DisplayName', 'Comb. Pressure (Fwd)');
        plot(zoomed_data.Time_s, zoomed_data.Comb_Pressure_Aft_bar, 'DisplayName', 'Comb. Pressure (Aft)');
        hold off;
        title_str = sprintf('%s - Pressures (Zoomed: %.2fs to %.2fs)', strrep(selected_field, '_', ' '), start_time, end_time);
        title(title_str);
        xlabel('Time (s)');
        ylabel('Pressure (bar)');
        legend;
        grid on;
        
        % 추력 데이터 플로팅
        subplot(2, 1, 2);
        plot(zoomed_data.Time_s, zoomed_data.Thrust_N);
        title_str = sprintf('%s - Thrust (Zoomed: %.2fs to %.2fs)', strrep(selected_field, '_', ' '), start_time, end_time);
        title(title_str);
        xlabel('Time (s)');
        ylabel('Thrust (N)');
        grid on;
        
        fprintf('\n선택한 시간 범위 [%.2f s, %.2f s]에 대한 플롯을 생성했습니다.\n', start_time, end_time);
        
        % 선택된 시간 범위 데이터 저장
        Zoomed_Time_Pressure_Data = zoomed_data(:, {'Time_s', 'Tank_Pressure_bar', 'Comb_Pressure_Fwd_bar', 'Comb_Pressure_Aft_bar'});
        Zoomed_Time_Thrust_Data = zoomed_data(:, {'Time_s', 'Thrust_N'});

        % 파일 이름에 부적합한 문자(.)를 'p'로 변경하여 유효한 파일명 생성
        filename_start_time = strrep(sprintf('%.2f', start_time), '.', 'p');
        filename_end_time = strrep(sprintf('%.2f', end_time), '.', 'p');
        
        zoomed_filename = fullfile(save_dir, sprintf('%s_zoomed_%sto%s.mat', selected_field, filename_start_time, filename_end_time));
        
        save(zoomed_filename, 'Zoomed_Time_Pressure_Data', 'Zoomed_Time_Thrust_Data');
        fprintf('선택 시간 범위 데이터를 다음 파일에 저장했습니다:\n  %s\n', zoomed_filename);
        
    catch ME
        fprintf('잘못된 입력입니다. 숫자를 입력해주세요. 오류: %s\n', ME.message);
    end
end
