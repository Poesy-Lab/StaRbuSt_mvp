function dx=flight_6dof(t,x)
%% Load

param=flight_param();
constant=flight_constant();

% <<< 전역 변수 선언
% global Nozzle_Thrust_Data % <<< .mat 파일에서 로드한 추력 데이터를 위한 전역 변수
global TMS_Thrust % <<< Excel 파일에서 로드한 추력 데이터를 위한 전역 변수
% >>> 전역 변수 선언 끝

%% Data Validation and Rate Calculation

if isempty(TMS_Thrust) % Nozzle_Thrust_Data -> TMS_Thrust
    error('TMS_Thrust is empty. Load data in main script.');
elseif size(TMS_Thrust, 2) ~= 2 % Nozzle_Thrust_Data -> TMS_Thrust
    error('TMS_Thrust must have 2 columns (time, thrust).');
else
    actual_burn_duration = TMS_Thrust(end, 1); % Nozzle_Thrust_Data -> TMS_Thrust
    if actual_burn_duration <= 1e-9 % 거의 0에 가까운 연소 시간 처리
        warning('Actual burn duration from TMS_Thrust data is near zero (%.4g s). Rates set to zero.', actual_burn_duration);
        actual_burn_duration = 0;
        effective_mass_rate = 0;
        effective_moi_rate = zeros(size(param.total_moi));
    else
        effective_mass_rate = param.propulsion_mass / actual_burn_duration;
        effective_moi_rate = (param.total_moi - param.end_moi) / actual_burn_duration;
    end
end

%% State Eq.

x_O = x(1:3, 1);
v_B = x(4:6, 1);
Euler = x(7:9, 1);
omega_BO = x(10:12, 1);
% quat = x(13:16, 1);

%% Quaternion Matrix

% q0 = quat(1,1);
% q1 = quat(2,1);
% q2 = quat(3,1);
% q3 = quat(4,1);
% 
% q_matrix = [q0, -q1, -q2, -q3;
%                 q1, q0, -q3, q2;
%                 q2, q3, q0, -q1;
%                 q3, -q2, q1, q0]; 

%% Coordinate Transformation Matrix 

R_BtoO=dcm_Otoa(Euler(3,1))*dcm_atob(Euler(2,1))*dcm_btoB(Euler(1,1));
R_OtoB=dcm_btoB(Euler(1,1))'*dcm_atob(Euler(2,1))'*dcm_Otoa(Euler(3,1))';

% R_BtoO=[q0^2+q1^2-q2^2-q3^2, 2*(q1*q2-q0*q3), 2*(q1*q3+q0*q2);
%             2*(q1*q2+q0*q3), q0^2+q2^2-q1^2-q3^2, 2*(q2*q3-q0*q1);
%             2*(q1*q3-q0*q2), 2*(q2*q3+q0*q1), q0^2+q3^2-q1^2-q2^2];
% R_OtoB=R_BtoO';

%% Dynamics 

spd = norm(v_B);

%% 질량 및 관성 모멘트 계산 수정
% 기존 param 값 대신 실제 연소 시간 기준으로 rate 재계산

% mass_rate = (t<=param.burn_time)*param.mass_rate;
% mass = param.total_mass-min(param.mass_rate*t, param.propulsion_mass);
propellant_consumed = min(effective_mass_rate * t, param.propulsion_mass);
mass = param.total_mass - propellant_consumed;

% moi_rate = (t<=param.burn_time)*param.moi_rate;
% moi = param.total_moi-min(param.moi_rate*t, param.total_moi-param.end_moi);
moi_change_at_t = effective_moi_rate * t;
total_moi_change = param.total_moi - param.end_moi;
actual_moi_change = min(moi_change_at_t, total_moi_change); % 요소별 min 사용 (대각 행렬 가정)
moi = param.total_moi - actual_moi_change;

Q_aero=(1/2)*constant.rho_sea*spd*v_B;
%% Thrust (Isp or TMS)

% global TMS_Thrust % Already declared at the top
% thrust = mass_rate*constant.g_0*param.ISP; <-- ISP 기반 추력 계산 주석 처리

% <<< .mat 데이터 기반 추력 보간 시작
% if isempty(Nozzle_Thrust_Data)
%     thrust = 0;
% else
%     % 전역 변수에 이미 시간 조정된 데이터가 있으므로, 바로 보간 수행
%     % t는 0부터 시작하는 조정된 시간임.
%     thrust = interp1(Nozzle_Thrust_Data(:, 1), Nozzle_Thrust_Data(:, 2), t, 'linear', 0); % 범위를 벗어날 경우 0을 반환하도록 지정
% end
% <<< .mat 데이터 기반 추력 보간 끝

if isempty(TMS_Thrust)
    thrust = 0;
    warning('TMS_Thrust data is empty. Thrust set to 0.'); % 경고 메시지 추가
elseif (t > TMS_Thrust(end,1))
    thrust = 0 ;
else
    thrust=interp1(TMS_Thrust(:,1), TMS_Thrust(:,2), t, 'linear', 0) ; % 'linear', 0 추가하여 범위 밖일때 0 반환
end %-- 기존 TMS_Thrust 보간 로직 활성화

W_O=[0;0;mass*constant.g_0];
W_B=R_OtoB*W_O;
AeroF_x = param.C_A*Q_aero(1,1)*param.ref_area;
AeroF_y = param.C_y*Q_aero(2,1)*param.ref_area; 
AeroF_z = param.C_z*Q_aero(3,1)*param.ref_area; 

% % if (t <= param.burn_time) && (thrust < -(W_B(1,1) + AeroF_x)) % 기존 로직 삭제
% % sigma_F=0;
% % else
% % sigma_F=[-AeroF_x;AeroF_y;AeroF_z]+W_B+[thrust;0;0];
% % end
sigma_F=[-AeroF_x;AeroF_y;AeroF_z]+W_B+[thrust;0;0]; % 항상 모든 힘을 계산

AeroM_x = param.C_l*Q_aero(1,1)*param.ref_area*param.diameter; 
AeroM_y = param.C_m*Q_aero(2,1)*param.ref_area*param.diameter; 
AeroM_z = param.C_n*Q_aero(3,1)*param.ref_area*param.diameter; 
SIgma_M = [AeroM_x;AeroM_y;AeroM_z];

%% Return

% <<< 발사 레일 조건 수정
% if (-x_O(3,1) < param.rail_h) && (t<=param.burn_time) % <-- 기존 조건 주석 처리
% if (-x_O(3,1) < param.rail_h) && (t <= param.burn_time) % <<< param.burn_time 사용 >> actual_burn_duration 으로 변경
if (-x_O(3,1) < param.rail_h) && (t <= actual_burn_duration) % <<< actual_burn_duration 사용
    % 발사 레일 위에 있을 때의 운동방정식 (자유도 제한)
    d_x_O= R_BtoO*v_B;
    d_Euler = [0;0;0];
    d_omega_BO = [0;0;0];

    % 레일 위에서의 힘/가속도 구속 조건 적용
    sigma_F_on_rail = sigma_F; % 위에서 계산된 전체 힘

    % 1. 전진 방향(동체 x축) 힘이 음수이면 0으로 설정 (뒤로 밀림 방지)
    if sigma_F_on_rail(1,1) < 0
        sigma_F_on_rail(1,1) = 0;
    end

    % 동체 기준 가속도 계산 (일단 구속되지 않은 상태로)
    a_B_temp = (1/mass)*sigma_F_on_rail;
    
    % 지상 좌표계 가속도로 변환하여 수직 운동 확인
    a_O_temp = R_BtoO * a_B_temp;

    % 2. 지면에 매우 가깝고(& 거의 정지), 아래로 가속하려 하면 수직 가속도 0 (땅파기 방지)
    %    x_O(3,1)은 보통 음수(아래 방향)이므로 -x_O(3,1)이 고도.
    %    v_B의 norm으로 속도 크기 확인.
    if (-x_O(3,1) < 0.01) && (a_O_temp(3,1) < 0) && (norm(v_B) < 0.1) 
        a_O_temp(3,1) = 0; % 지상 Z축(수직) 가속도 0
        if d_x_O(3,1) < 0 % 추가: 만약 계산된 수직 속도도 아래 방향이면 0으로 설정
            d_x_O(3,1) = 0;
        end
    end
    
    % 최종적으로 제한된 가속도를 다시 동체 좌표계로 변환
    a_B_constrained = R_OtoB * a_O_temp;
    
    % d_v_B 계산 (omega_BO가 0이므로 cross 항은 0)
    d_v_B = a_B_constrained; % cross(omega_BO, v_B)는 omega_BO가 0이므로 생략 가능
    
else
    % 자유 비행
    d_x_O= R_BtoO*v_B;
    % 지면 충돌 방지 로직 추가 (자유 비행 시)
    if (-x_O(3,1) < 0.01) && (d_x_O(3,1) < 0)
        d_x_O(3,1) = 0;
        % 지면 근처에서 아래로 향하는 속도가 있다면, 해당 속도 성분도 0으로 만들어
        % 다음 스텝에서 다시 파고들려는 것을 방지
        v_O_temp = R_BtoO*v_B;
        if v_O_temp(3,1) < 0
            v_O_temp(3,1) = 0;
            v_B = R_OtoB*v_O_temp; % 수정된 v_B를 다시 할당 (주의: 상태 변수 직접 수정)
                                   % RK4 내부에서 x가 다음 스텝으로 넘어갈 때 이 수정이 반영되지는 않음.
                                   % 따라서 이 로직은 d_x_O(3,1) = 0과 함께 주로 사용되어야 함.
                                   % 보다 근본적인 해결은 htg_event_flight.m 강화 또는 물리 모델 개선.
        end
    end

    d_v_B = (1/mass)*sigma_F-(cross(omega_BO, v_B));
    d_Euler = Omega2dEuler(omega_BO, Euler);
    d_omega_BO = moi\(SIgma_M-cross(omega_BO,moi*omega_BO));
    % d_quat = (1/2)*q_matrix*[0; omega_BO(1,1); omega_BO(2,1); omega_BO(3,1)];
end

dx=[d_x_O;d_v_B;d_Euler;d_omega_BO];
% dx=[d_x_O;d_v_B;d_Euler;d_omega_BO; d_quat];

% 최종 반환 직전에 고도 하한 강제
% x_O(3,1)은 지상 Z축 위치 (아래 방향이 양수)
% dx(3,1)은 지상 Z축 속도 (아래 방향이 양수)
if (abs(x(3,1)) < 1e-4) && (dx(3,1) > 0) % 고도가 거의 0이고, 아래로 내려가려 한다면
    dx(3,1) = 0; % 수직 하강 속도 0으로 강제
end

end


%% DCM PSI (3)

function dcm=dcm_Otoa(psi)

dcm=[cos(psi), -sin(psi), 0;
        sin(psi), cos(psi), 0;
        0, 0, 1];
end

%% DCM THETA (2)

function dcm=dcm_atob(theta)

dcm=[cos(theta), 0, sin(theta);
        0, 1, 0;
        -sin(theta), 0, cos(theta)];
end

%% DCM PHI (1)

function dcm=dcm_btoB(phi)

dcm=[1, 0, 0;
        0, cos(phi), -sin(phi);
        0, sin(phi), cos(phi)];
end

%% Omega to dEuler

function d_Euler = Omega2dEuler(Omega_BO,Euler)

sin_phi = sin(Euler(1,1));
cos_phi = cos(Euler(1,1));
cos_theta = cos(Euler(2,1));
tan_theta = tan(Euler(2,1));

d_Euler = [Omega_BO(1,1)+Omega_BO(2,1)*sin_phi*tan_theta+Omega_BO(3,1)*cos_phi*tan_theta; 
           Omega_BO(2,1)*cos_phi-Omega_BO(3,1)*sin_phi; 
           Omega_BO(2,1)*sin_phi/cos_theta+Omega_BO(3,1)*cos_phi/cos_theta];

end


