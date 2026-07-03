% MATLAB Code for Calculating Combustion Instability Frequencies
% 이 코드는 제공된 식을 기반으로 하며, 실제 로켓의 복잡한 현상을
% 모두 반영하지는 못합니다. 참고용으로 사용하세요.

clear;
clc;
close all

disp('---------------------------------------------------------------------');
disp('하이브리드 로켓 연소불안정 주파수 계산기');
disp('---------------------------------------------------------------------');

% --- 입력 변수 (사용자가 실제 값으로 수정해야 함) ---
% 모든 단위는 SI 단위계 (m, kg, s, K, Pa 등)를 기준으로 합니다.

% 1. 길이방향 음향 모드 (Longitudinal Acoustic Mode)
n_longitudinal = 1;       % 모드 수 (보통 1, 2, 3 등을 고려)
gamma_gas = 1.14;          % 연소 가스의 비열비 (무차원, 예: 1.1 ~ 1.3)
R_gas_specific = 287;     % 연소 가스의 특정 기체 상수 (J/kg·K, 공기 예시, 실제 연소가스 값 사용)
T_avg_comb_gas = 2500;    % 연소 가스의 평균 온도 (K, 예: 2000 ~ 3500 K)
L_m_combustor = 0.5;      % 연소실의 유효 음향 길이 (m)
                          % (예: 인젝터 면부터 노즐 수축부 또는 임계점까지의 길이)
                          % (전방연소실 길이 + 그레인 길이 + 후방연소실 길이)

% 2. 헬름홀츠 모드 (Helmholtz Mode)
% 전방 연소실이 공동(cavity) 역할을 하고, 연료 포트 입구가 목(neck) 역할을 하거나,
% 또는 인젝터 오리피스가 목, 전방 연소실이 공동 역할을 할 수 있습니다.
% 여기서는 전방 연소실을 공동, 연료 그레인 입구를 목으로 가정해볼 수 있습니다.
% 또는 인젝터 오리피스(목)와 전방연소실(공동)로 가정할 수도 있습니다.
% 어떤 부분을 cavity와 neck으로 볼 지에 따라 D_neck, V_cavity, L_neck 값을 설정해야 합니다.

% 예시: 전방 연소실(cavity)과 연료 포트 입구(neck)
c_sound_cavity = sqrt(gamma_gas * R_gas_specific * T_avg_comb_gas); % 공동 내 음속 (m/s), 연소가스 기준
D_neck = 0.03;            % "목(neck)"의 직경 (m) (예: 단일 연료 포트 직경 또는 등가 직경)
V_cavity = 0.0005;        % "공동(cavity)"의 체적 (m^3) (예: 전방 연소실 체적)
L_neck = 0.01;            % "목(neck)"의 길이 (m) (예: 연료 그레인 입구 단면의 두께 또는 전방격벽 두께)
                          % 다이아프램을 사용하지 않으므로, 연료 그레인 포트가 시작되는 부분의
                          % 유효 길이 또는 전방 연소실과 그레인 사이 격벽 두께 (만약 있다면)

% 3. 와류 진동 모드 (Vortex Shedding Mode)
St_strouhal = 0.25;       % 스트로홀 수 (Strouhal number, 무차원, 보통 0.2 ~ 0.5)
U_flow_vortex = 50;       % 와류를 발생시키는 주요 유동의 평균 속도 (m/s)
                          % (예: 연료 포트 입구에서의 유속, 또는 인젝터 출구에서 전방연소실로 확장되는 지점의 유속)
L_char_vortex = 0.01;     % 와류 발생부의 특징적인 길이 (m)
                          % (예: 전방연소실-연료포트 간 스텝 높이, 인젝터 오리피스 직경, 연료 포트 직경)

% 4. 하이브리드 저주파 모드 (Hybrid Low Frequency Mode, Chuffing)
tau_bl_thermal_lag = 0.005; % 고체 연료의 열 관성(thermal lag)에 의한 시간 지연 (s, 예: 0.001 ~ 0.02 s)
OF_ratio = 6.0;             % 산화제 대 연료 질량 유량비 (O/F, 무차원)
G_ox_avg = 400;             % 평균 산화제 질량 플럭스 (kg/m^2·s) (총 산화제 유량 / 총 포트 단면적)
R_ox_specific = 188.9;      % *산화제*의 특정 기체 상수 (J/kg·K, 예: N2O의 경우 약 188.9 J/kg·K)
T_avg_ox_vapor = 300;       % *산화제 기화 또는 주입 시* 평균 온도 (K) (LN2O 경우 상온 근처 또는 기화 후 온도)
C_star_velocity = 1500;     % 특성 속도 (C-star, m/s)
L_P_grain = 0.3;            % 연료 포트의 길이 (즉, 그레인 길이) (m)
c_sound_HL_denom = sqrt(gamma_gas * R_gas_specific * T_avg_comb_gas); % 분모의 c, 연소실 음속으로 가정 (m/s)
                            % 이 값은 논문에 따라 다른 기준 속도일 수 있음.

% --- 계산 ---

% 1. 길이방향 음향 모드 주파수
c_sound_comb_gas = sqrt(gamma_gas * R_gas_specific * T_avg_comb_gas);
f_L = (n_longitudinal * c_sound_comb_gas) / (2 * L_m_combustor);

% 2. 헬름홀츠 모드 주파수
A_neck = pi * (D_neck/2)^2; % 목의 단면적
L_eff_neck = L_neck + 0.8 * D_neck; % 목의 유효 길이 (말단 보정 포함)
f_H = (c_sound_cavity / (2*pi)) * sqrt(A_neck / (V_cavity * L_eff_neck));
% 이미지의 식: f_H = (c / (2*pi)) * sqrt( (D_front^2 * pi / 4) / (V_cavity * (L_front + 0.8*D_front)) )
% 위 A_neck, L_eff_neck을 사용한 식과 동일합니다. (D_front -> D_neck, L_front -> L_neck으로 변수명 변경)

% 3. 와류 진동 모드 주파수
f_VS = (St_strouhal * U_flow_vortex) / L_char_vortex;

% 4. 하이브리드 저주파 모드 주파수
% f_HL = (0.48 / tau_bl) * (2 + (1/OF) - (G_o,avg * R * T_avg) / (c' * L_P * c))
term1_HL = 2 + (1/OF_ratio);
% 주의: R*T_avg 부분은 산화제 기준인지, 연소가스 기준인지 논문마다 다를 수 있습니다.
% 여기서는 산화제 기화 관련 온도 및 기체상수를 사용합니다 (G_o,avg와 관련하여).
term2_HL_num = G_ox_avg * R_ox_specific * T_avg_ox_vapor;
term2_HL_den = C_star_velocity * L_P_grain * c_sound_HL_denom;
term2_HL = term2_HL_num / term2_HL_den;

f_HL = (0.48 / tau_bl_thermal_lag) * (term1_HL - term2_HL);
% 만약 (term1_HL - term2_HL) 부분이 음수가 나오면, 해당 모델이 현재 조건에서
% 불안정을 예측하지 않거나, 입력 파라미터가 물리적 범위를 벗어났을 수 있습니다.

% --- 결과 출력 ---
disp(' ');
disp('--- 계산된 연소불안정 주파수 ---');
fprintf('1. 길이방향 음향 모드 (f_L, n=%d): %.2f Hz\n', n_longitudinal, f_L);
fprintf('2. 헬름홀츠 모드 (f_H):             %.2f Hz\n', f_H);
fprintf('3. 와류 진동 모드 (f_VS):           %.2f Hz\n', f_VS);
if (term1_HL - term2_HL) > 0
    fprintf('4. 하이브리드 저주파 모드 (f_HL):   %.2f Hz\n', f_HL);
else
    fprintf('4. 하이브리드 저주파 모드 (f_HL):   계산 불가 (괄호 안이 음수 또는 0)\n');
end
disp('------------------------------------');
disp(' ');
disp('참고 사항:');
disp('- 각 모드의 주파수가 서로 가깝거나 정수배 관계일 때 공진 가능성이 높아집니다.');
disp('- 이 계산은 단순화된 모델이며, 실제 현상은 더 복잡할 수 있습니다.');
disp('- 입력 변수의 정확도가 결과에 큰 영향을 미칩니다.');
disp('- f_HL 계산 시 사용된 R, T_avg, c 값은 해당 모드의 물리적 특성에 맞게 설정해야 합니다.');
disp('  (여기서는 산화제 기화 관련 값과 연소실 음속을 일부 사용했습니다.)');