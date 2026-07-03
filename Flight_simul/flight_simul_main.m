clc
% clear
close all

% global Nozzle_Thrust_Data % <<< .mat 파일에서 로드한 추력 데이터를 위한 전역 변수 선언
global TMS_Thrust % <<< Excel 파일에서 로드한 추력 데이터를 위한 전역 변수 선언

%% Load Parameter

param=flight_param();
constant=flight_constant();
flight_simul_dir = fileparts(mfilename('fullpath')); % 이 스크립트 위치 기준 상대 경로
TMS_Thrust=readmatrix(fullfile(flight_simul_dir, "hybrid_tms_thrust.xlsx")); % <<< Excel 파일 로딩 활성화
% TMS_Thrust=readmatrix(fullfile(flight_simul_dir, "NOSHIRO_고흥_고체로켓 추력 DATA_new.xlsx")); % <<< Excel 파일 로딩 활성화
actual_burn_duration_main = TMS_Thrust(end,1); % <<< 실제 연소 종료 시간 저장

% % <<< 새로운 .mat 파일 로딩 시작 (주석 처리)\

% thrust_data_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Mat_Data\2025_SRS_Noshiro_output_Nozzle_Thrust_vs_Time.mat"
% % thrust_data_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Mat_Data\2025_SRS_300_output_Nozzle_Thrust_vs_Time.mat"
% % thrust_data_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Mat_Data\2025_SRS_Hybrid_Burn_output_Nozzle_Thrust_vs_Time.mat"
% % thrust_data_path = "C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\Mat_Data\2025_SRS_Hybrid_Burn_Ideal_output_Nozzle_Thrust_vs_Time.mat"
% fprintf('Loading thrust data from: %s\n', thrust_data_path);
% try
%     % .mat 파일을 로드합니다.
%     loaded_data = load(thrust_data_path);
% 
%     % .mat 파일에 time_vector, thrust_vector 변수가 있는지 확인합니다.
%     if isfield(loaded_data, 'time_vector') && isfield(loaded_data, 'thrust_vector')
%         original_time = loaded_data.time_vector(:);
%         original_thrust = loaded_data.thrust_vector(:);
% 
%         % 0보다 큰 첫 번째 추력 값의 인덱스와 시간을 찾습니다.
%         first_thrust_idx = find(original_thrust > 1e-9, 1, 'first');
% 
%         if isempty(first_thrust_idx)
%             error('No significant thrust found in the data.');
%         end
% 
%         thrust_start_time_original = original_time(first_thrust_idx);
%         fprintf('Original thrust start time: %.4f s\n', thrust_start_time_original);
% 
%         % 추력 시작 시점부터의 데이터만 사용하고 시간 축을 이동시킵니다.
%         adjusted_time_vector = original_time(first_thrust_idx:end) - thrust_start_time_original;
%         adjusted_thrust_vector = original_thrust(first_thrust_idx:end);
% 
%         % 전역 변수에 조정된 데이터를 저장합니다.
%         Nozzle_Thrust_Data = [adjusted_time_vector, adjusted_thrust_vector];
%         fprintf('Thrust data loaded and time adjusted. New time range: 0 to %.4f s\n', adjusted_time_vector(end));
% 
%         % --- 시뮬레이션 시간 설정 수정 ---
%         t_0 = 0; % 시작 시간은 0으로 고정
%         t_f = 60; % 종료 시간은 조정된 데이터의 마지막 시간
%         dt = 0.01;
%         % dt는 기존 값 사용
%         time = t_0:dt:t_f; % 수치 적분 시간 벡터 재생성
%         fprintf('Simulation time set from %.2f s to %.2f s with dt=%.4f s\n', t_0, t_f, dt);
%         % --- 시뮬레이션 시간 설정 수정 끝 ---
% 
%     else
%         error('.mat file does not contain expected "time_vector" and "thrust_vector" variables.');
%     end
% catch ME
%     error('Failed to load thrust data from .mat file: %s\n%s', thrust_data_path, ME.message);
% end
% % <<< 새로운 .mat 파일 로딩 끝 (주석 처리)

% --- 시뮬레이션 시간 설정 (Excel 데이터 사용 시) ---
t_0 = 0; 
t_f = 60; % 시뮬레이션 전체 시간 (필요시 TMS_Thrust(end,1) 기준으로 조절)
dt = 0.01;
time = t_0:dt:t_f; 
fprintf('Simulation time set from %.2f s to %.2f s with dt=%.4f s (using Excel mode)\n', t_0, t_f, dt);
% --- 시뮬레이션 시간 설정 끝 ---

%% Initial State

init_x_O=[0;0;0];
init_v_B=[0;0;0];
init_E_BO=[0;85;90]*pi/180;
init_omega_BO=[0;0;0];
% init_quat = [Euler2quat(init_E_BO)];
init_state=[init_x_O;init_v_B;init_E_BO;init_omega_BO];
% init_state=[init_x_O;init_v_B;init_E_BO;init_omega_BO;init_quat];

% t_0 = 0; % <-- 기존 시간 설정 주석 처리
% t_f = 60; % <-- 기졸 시간 설정 주석 처리
% dt = 0.01; % <-- dt는 위에서 사용되므로 여기서는 주석 처리 (또는 삭제)
% % dt = 0.0002;
% time = t_0:dt:t_f; % <-- 기존 시간 벡터 생성 주석 처리

%% Numerical Integration 

[t_RK4, x_RK4] = int_RK4(@flight_6dof,time,init_state,@htg_event_flight); % <<< @htg_event_polaris1 -> @htg_event_flight
x_RK4(:, 3) = -x_RK4(:, 3);
x_RK4(:, 7:9) = x_RK4(:, 7:9)*180/pi;
% x_RK4(:, 6) = -x_RK4(:, 6);
% t_burn_index=find(t_RK4 == round(param.burn_time, 1)); % 기존 라인 주석 처리
[~, t_burn_index_actual] = min(abs(t_RK4 - actual_burn_duration_main)); % <<< 실제 연소 종료 시점에 가장 가까운 인덱스 찾기
burn_alt = x_RK4(t_burn_index_actual, 3); % <<< 수정된 인덱스 사용
time_at_burn_alt = t_RK4(t_burn_index_actual); % <<< 연소 종료 시점의 시간

max_alt=max(x_RK4(:, 3));
idx_max_alt = find(x_RK4(:,3) == max_alt, 1, 'first'); % <<< 최대 고도 도달 인덱스
time_at_max_alt = t_RK4(idx_max_alt); % <<< 최대 고도 도달 시간

% 최대 고도 도달 전까지의 데이터 슬라이싱
% idx_max_alt는 항상 1 이상입니다.
t_data_for_calc = t_RK4(1:idx_max_alt);
x_data_for_calc = x_RK4(1:idx_max_alt, :);

% 최대 고도 도달 전에서의 속도 크기 계산
max_velocity = NaN;
time_at_max_velocity = NaN;
if ~isempty(x_data_for_calc) && size(x_data_for_calc,1) > 0 % 데이터가 비어있지 않은지 확인
    velocities_norm_calc = vecnorm(x_data_for_calc(:, 4:6), 2, 2);
    if ~isempty(velocities_norm_calc) % vecnorm 결과가 비어있지 않은지 확인
        [max_velocity_val, idx_max_velocity_local] = max(velocities_norm_calc);
        if ~isempty(idx_max_velocity_local) % max 결과가 비어있지 않은지 확인
            max_velocity = max_velocity_val;
            time_at_max_velocity = t_data_for_calc(idx_max_velocity_local);
        end
    end
end

% 최대 고도 도달 전에서의 가속도 크기 근사 계산 (수치 미분)
max_acceleration_approx = NaN;
time_at_max_acceleration_approx = NaN;

if length(t_data_for_calc) > 1
    v_B_data_calc = x_data_for_calc(:, 4:6);
    dv_B_calc = diff(v_B_data_calc);
    dt_rk4_calc = diff(t_data_for_calc);
    
    % dt_rk4_calc 요소 중 0이 있는지 확인하고 eps로 대체
    dt_rk4_calc(dt_rk4_calc == 0) = eps;
    
    a_B_approx_components_calc = dv_B_calc ./ dt_rk4_calc;
    
    % 가속도 벡터 크기 계산 (diff로 인해 길이가 1 줄어들었으므로 첫 번째 시간 스텝에 대한 가속도는 없음)
    accelerations_norm_values_calc = vecnorm(a_B_approx_components_calc, 2, 2);
    
    if ~isempty(accelerations_norm_values_calc)
        [current_max_accel, idx_max_accel_local_diff] = max(accelerations_norm_values_calc);
        % idx_max_accel_local_diff는 accelerations_norm_values_calc에서의 인덱스 (즉, diff 결과에서의 인덱스)
        % t_data_for_calc에서는 +1 해줘야 함 (예: diff(t(1:3))의 결과는 t(2)-t(1), t(3)-t(2) 이므로, max 결과 인덱스 1은 t(2)에 해당)
        if ~isempty(idx_max_accel_local_diff) && ~isnan(current_max_accel) % max 결과가 비어있지 않고 NaN이 아닌지 확인
            max_acceleration_approx = current_max_accel;
            time_at_max_acceleration_approx = t_data_for_calc(idx_max_accel_local_diff + 1);
        end
    end
end

% 발사대 탈출 속도 계산 및 출력
rail_escape_velocity = NaN;
rail_escape_time = NaN;
for i = 1:length(t_RK4)
    current_altitude = x_RK4(i,3); % x_RK4(:,3)은 이미 -를 곱해서 양의 고도로 변환된 상태임
    if current_altitude >= param.rail_h
        v_B_escape = x_RK4(i, 4:6);
        rail_escape_velocity = norm(v_B_escape);
        rail_escape_time = t_RK4(i);
        fprintf('발사대 탈출 시간: %.2f s, 고도: %.2f m, 속도: %.2f m/s\n', rail_escape_time, current_altitude, rail_escape_velocity);
        break; % 첫 번째 탈출 지점만 기록
    end
end
if isnan(rail_escape_velocity)
    fprintf('시뮬레이션 시간 내에 발사대를 탈출하지 못했습니다 (레일 높이: %.2f m).\n', param.rail_h);
end

fprintf('연소 종료 시간: %.2f s, 도달 고도: %.2f m\n', time_at_burn_alt, burn_alt);
fprintf('최대 고도 도달 시간: %.2f s, 최종 비행 도달 고도: %.2f m \n', time_at_max_alt, max_alt);
fprintf('최대 속도: %.2f m/s (시간: %.2f s)\n', max_velocity, time_at_max_velocity);
if ~isnan(max_acceleration_approx)
    fprintf('최대 가속도: %.2f m/s^2 (시간: %.2f s)\n', max_acceleration_approx, time_at_max_acceleration_approx);
else
    fprintf('최대 고도 도달 전 최대 가속도 (근사치)를 계산할 수 없습니다.\n');
end

% wind=2;
% rock=10;
% wc_ang=atan(rock/wind);
% Lost_H=max_alt*(1-sin(wc_ang));

% figure(1)
% subplot(2,1,1);
% plot(time, x_RK4(:,3))
% xlabel('Time(s)')
% ylabel('Altitude (m)')
% title('Altitude-Time')
% subplot(2,1,2);
% plot(TMS_Thrust(:,1), TMS_Thrust(:,2))
% xlabel('Time(s)')
% ylabel('Thrust (N)')
% title('Thrust-Time')

figure(1)
hold on; grid on;
% 전체 화면으로 설정
    set(gcf, 'WindowState', 'maximized');
square = [1 1; -1 1; -1 -1; 1 -1];
trj = plot3(x_RK4(1,1),x_RK4(1,2),x_RK4(1,3));
pt = plot3(x_RK4(1,1),x_RK4(1,2),x_RK4(1,3),'s');

% % % % 아래 코드는 chatgpt가 생성한 로켓 3D형상
%  % 로켓 몸통 (원통형)
%     [X_body, Y_body, Z_body] = cylinder([0.1 0.05]);
%     Z_body = Z_body * 2 - 1; % 높이 조절
%     body=surf(X_body, Y_body, Z_body, 'FaceColor', 'b');
% 
%     % 로켓 뾰족한 부분 (원뿔 형태)
%     [X_nose, Y_nose, Z_nose] = cylinder([0.05 0]);
%     Z_nose = Z_nose + 1; % 높이 조절
%     nose=surf(X_nose, Y_nose, Z_nose, 'FaceColor', 'y');
% 
%     % 로켓 엔진 (원통형)
%     [X_engine, Y_engine, Z_engine] = cylinder([0.1 0.1]);
%     Z_engine = Z_engine * -0.2 -1; % 높이 조절
%     engine=surf(X_engine, Y_engine, Z_engine, 'FaceColor', 'r');
% 
%     % 로켓 꼬리 (원통형)
%     [X_tail, Y_tail, Z_tail] = cylinder([0.2 0]);
%     Z_tail = Z_tail - 1; % 높이 조절
%     tail=surf(X_tail, Y_tail, Z_tail, 'FaceColor', 'y');
% % % % 

hold off;
view(20, 10)
xlim([-100, 100]);
ylim([-100, 100]);
zlim([0, 500]);
axis equal
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
legend('RK4');
body_grp = hgtransform('Parent',gca);
set(pt,'parent',body_grp);
% set(body,'parent',body_grp);
% set(nose,'parent',body_grp);
% set(engine,'parent',body_grp);
% set(tail,'parent',body_grp);
anim_start = clock;
anim_speed =3;
time_text = text(x_RK4(1,1),x_RK4(1,2),x_RK4(1,3)+1,sprintf('%.2f',t_RK4(1,1)));
 % 시작 딜레이
    pause(0.5);
for id = 1:length(t_RK4)
    real_time = etime(clock,anim_start);
    time_to_go = (t_RK4(id,1)-t_RK4(1,1))/anim_speed - real_time;
    if time_to_go > 0
        pause(time_to_go)
    end
    if ~isnan(t_RK4(id,1))
        set(time_text,'String',sprintf('%.2f',t_RK4(id,1)))
        set(trj,'XData',x_RK4(1:id,1),'YData',x_RK4(1:id,2),'ZData',x_RK4(1:id,3))
        body_grp.Matrix = makehgtform('translate',x_RK4(id,1:3)-x_RK4(1,1:3));
      else
        break;
    end
end
% 위 그래프는 RK4에 대한 애니메이션을 보여줌 