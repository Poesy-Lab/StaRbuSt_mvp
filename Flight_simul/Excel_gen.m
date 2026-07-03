clc;
clearvars; % 'clear all'보다는 'clearvars'가 권장됩니다.
close all;

fprintf('스크립트 시작...\n');

try
    % =================================================================
    % 1. 추력(Thrust) 데이터 처리 및 저장
    % =================================================================
    fprintf('\n--- 추력 데이터 처리 시작 ---\n');

    % .mat 파일 경로 설정
    thrust_data_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Mat_Data\2025_SRS_Hybrid_Oneshot_Cd38_output_Nozzle_Thrust_vs_Time.mat";
    % thrust_data_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Mat_Data\2025_SRS_Hybrid_Oneshot_Cd38_secondrun_beta_output_Nozzle_Thrust_vs_Time.mat";

    % 저장할 파일 경로 (Excel 및 CSV)
    excel_thrust_output_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Flight_simul\hybrid_tms_thrust.xlsx";
    csv_thrust_output_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Flight_simul\hybrid_tms_thrust.csv";

    fprintf('선택된 추력 데이터 파일: %s\n', thrust_data_path);

    % .mat 파일 로드
    fprintf('추력 데이터 로딩 중...\n');
    if ~isfile(thrust_data_path)
        error('지정된 추력 .mat 파일(%s)을 찾을 수 없습니다.', thrust_data_path);
    end
    loaded_thrust_data = load(thrust_data_path);

    % 데이터 유효성 검사
    if ~isfield(loaded_thrust_data, 'time_vector') || ~isfield(loaded_thrust_data, 'thrust_vector')
        error('추력 .mat 파일에 "time_vector" 및/또는 "thrust_vector" 변수가 없습니다.');
    end
    
    original_time = loaded_thrust_data.time_vector(:);
    original_thrust = loaded_thrust_data.thrust_vector(:);

    if length(original_time) ~= length(original_thrust)
        error('time_vector와 thrust_vector의 길이가 일치하지 않습니다.');
    end
    if isempty(original_time)
        error('로드된 추력 데이터가 비어있습니다.');
    end
    
    fprintf('원본 추력 데이터 포인트 수: %d\n', length(original_time));

    % 유의미한 추력 구간 추출 및 시간 축 조정
    first_thrust_idx = find(original_thrust > 1e-9, 1, 'first');
    
    adjusted_time_vector = [];
    adjusted_thrust_vector = [];
    thrust_start_time_original = NaN;

    if isempty(first_thrust_idx)
        warning('데이터에서 유의미한 추력 구간을 찾을 수 없어, 질량 유량 처리를 건너뜁니다.');
        adjusted_time_vector = original_time;
        adjusted_thrust_vector = original_thrust;
    else
        thrust_start_time_original = original_time(first_thrust_idx);
        fprintf('원본 데이터에서 실제 추력 시작 시간: %.4f s\n', thrust_start_time_original);

        adjusted_time_vector = original_time(first_thrust_idx:end) - thrust_start_time_original;
        adjusted_thrust_vector = original_thrust(first_thrust_idx:end);
        
        fprintf('시간 축 조정 완료. 새 시간 범위: 0 ~ %.4f s, 데이터 포인트 수: %d\n', adjusted_time_vector(end), length(adjusted_time_vector));
    
        % 음수 값 제거: 추력 값이 0보다 작아지는 첫 지점부터 데이터를 자릅니다.
        first_negative_thrust_idx = find(adjusted_thrust_vector < 0, 1, 'first');
        if ~isempty(first_negative_thrust_idx)
            fprintf('음수 추력 값을 발견하여 해당 지점부터 데이터를 제거합니다 (인덱스: %d).\n', first_negative_thrust_idx);
            adjusted_time_vector = adjusted_time_vector(1:first_negative_thrust_idx-1);
            adjusted_thrust_vector = adjusted_thrust_vector(1:first_negative_thrust_idx-1);
            if isempty(adjusted_time_vector)
                fprintf('경고: 음수 값 제거 후 남은 데이터가 없습니다.\n');
            else
                fprintf('음수 값 제거 후 데이터 포인트 수: %d, 시간 범위: 0 ~ %.4f s\n', length(adjusted_time_vector), adjusted_time_vector(end));
            end
        end
    end
    
    % Excel 및 CSV 파일로 저장
    output_thrust_table = table(adjusted_time_vector, adjusted_thrust_vector, 'VariableNames', {'Time_s', 'Thrust_N'});
    
    fprintf('처리된 추력 데이터를 파일로 저장 중...\n');
    if isfile(excel_thrust_output_path), delete(excel_thrust_output_path); end
    writetable(output_thrust_table, excel_thrust_output_path);
    fprintf('-> Excel 저장 완료: %s\n', excel_thrust_output_path);

    if isfile(csv_thrust_output_path), delete(csv_thrust_output_path); end
    writetable(output_thrust_table, csv_thrust_output_path);
    fprintf('-> CSV 저장 완료: %s\n', csv_thrust_output_path);
    
    fprintf('--- 추력 데이터 처리 완료 ---\n');

    % =================================================================
    % 2. 질량 유량(Mdot) 데이터 처리 및 저장
    % =================================================================
    fprintf('\n--- 질량 유량 데이터 처리 시작 ---\n');

    if isnan(thrust_start_time_original)
        fprintf('유의미한 추력 시작 시간을 찾지 못했으므로, 질량 유량 처리를 건너뜁니다.\n');
    else
        % .mat 파일 경로 설정
        mdot_data_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Mat_Data\2025_SRS_Hybrid_Oneshot_Cd5_output_Comb_Mdot_vs_Time.mat";

        % 저장할 파일 경로 (Excel 및 CSV)
        excel_mdot_output_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Flight_simul\hybrid_tms_mdot.xlsx";
        csv_mdot_output_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Flight_simul\hybrid_tms_mdot.csv";
        
        fprintf('선택된 질량 유량 데이터 파일: %s\n', mdot_data_path);
        
        % .mat 파일 로드
        fprintf('질량 유량 데이터 로딩 중...\n');
        if ~isfile(mdot_data_path)
            error('지정된 질량 유량 .mat 파일(%s)을 찾을 수 없습니다.', mdot_data_path);
        end
        loaded_mdot_data = load(mdot_data_path);

        % 데이터 유효성 검사
        if ~isfield(loaded_mdot_data, 'time_vector') || ~isfield(loaded_mdot_data, 'mdot_vector')
            error('질량 유량 .mat 파일에 "time_vector" 및/또는 "mdot_vector" 변수가 없습니다.');
        end
        
        mdot_time_orig = loaded_mdot_data.time_vector(:);
        mdot_val_orig = loaded_mdot_data.mdot_vector(:);

        if length(mdot_time_orig) ~= length(mdot_val_orig)
            error('mdot_vector와 time_vector의 길이가 일치하지 않습니다.');
        end
        
        % NaN 값을 포함하는 행 제거
        nan_rows = isnan(mdot_time_orig) | isnan(mdot_val_orig);
        if any(nan_rows)
            fprintf('%d개의 NaN 데이터 포인트를 제거합니다.\n', sum(nan_rows));
            mdot_time_orig(nan_rows) = [];
            mdot_val_orig(nan_rows) = [];
        end
        
        if isempty(mdot_time_orig)
            error('로드된 질량 유량 데이터가 비어있습니다.');
        end

        % 추력 데이터의 시간 축에 맞춰 질량 유량 데이터 보간
        fprintf('추력 시간 축에 맞춰 질량 유량 데이터를 보간합니다...\n');
        target_mdot_time_points = adjusted_time_vector + thrust_start_time_original;
        
        % interp1을 사용하여 보간. 'linear'와 'extrap' 옵션 사용.
        % extrap은 데이터 범위를 벗어나는 점들도 추정해줍니다.
        % 만약 범위를 벗어나는 값을 0으로 하고 싶다면 추가 처리가 필요합니다.
        adjusted_mdot_vector = interp1(mdot_time_orig, mdot_val_orig, target_mdot_time_points, 'linear', 'extrap');
        
        % 시간 축은 추력 데이터의 것과 동일하게 사용
        final_mdot_time = adjusted_time_vector;
        final_mdot_values = adjusted_mdot_vector;
        
        fprintf('데이터 보간 완료. 데이터 포인트 수: %d\n', length(final_mdot_time));
        
        % 질량 유량 데이터에서 음수 값을 0으로 처리
        negative_mdot_indices = final_mdot_values < 0;
        if any(negative_mdot_indices)
            fprintf('%d개의 음수 질량 유량 값을 0으로 대체합니다.\n', sum(negative_mdot_indices));
            final_mdot_values(negative_mdot_indices) = 0;
        end
        
        % Excel 및 CSV 파일로 저장
        output_mdot_table = table(final_mdot_time, final_mdot_values, 'VariableNames', {'Time_s', 'Mdot_kg_s'});
        
        fprintf('처리된 질량 유량 데이터를 파일로 저장 중...\n');
        if isfile(excel_mdot_output_path), delete(excel_mdot_output_path); end
        writetable(output_mdot_table, excel_mdot_output_path);
        fprintf('-> Excel 저장 완료: %s\n', excel_mdot_output_path);

        if isfile(csv_mdot_output_path), delete(csv_mdot_output_path); end
        writetable(output_mdot_table, csv_mdot_output_path);
        fprintf('-> CSV 저장 완료: %s\n', csv_mdot_output_path);
    end
    
    fprintf('--- 질량 유량 데이터 처리 완료 ---\n');

catch ME
    fprintf(2, '\n오류 발생: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf(2, '파일: %s, 라인: %d\n', ME.stack(1).name, ME.stack(1).line);
    end
    fprintf(2, '스크립트 실행 중단.\n');
end

fprintf('\n스크립트 종료.\n');
