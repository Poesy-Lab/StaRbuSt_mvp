---
tags:
  - EOS
  - 상태방정식
  - 유체
  - 물성치
  - 플롯
  - 검증
---
# 소개
- `plot_EOS.m`은 MATLAB 환경에서 **지정된 유체**의 상태방정식(EOS) 기반 계산 결과와 NIST 기준 데이터를 비교하여 시각화하는 스크립트입니다.
- 사용자가 스크립트 상단에서 유체 이름을 설정하면, 해당 유체의 NIST 데이터를 엑셀 파일에서 로드하고, 대응하는 `FluidEOS` 상속 클래스를 이용하여 열역학적 및 전달 특성(압력, 밀도, 내부에너지, 엔탈피, 엔트로피, 비열, 음속 등)을 계산합니다.
- 온도에 따른 각 물성치에 대해 EOS 계산값과 NIST 데이터를 함께 그래프로 나타내어 EOS 모델의 정확성과 신뢰성을 시각적으로 검증할 수 있습니다.
- 다양한 유체 모델 개발 및 검증, 2상 유동 시뮬레이션의 물성치 데이터 확인 등에 활용될 수 있습니다.

# 사용 가이드라인
1.  **유체 이름 설정**: 스크립트 상단의 `%% ---- 사용자 설정 ----` 섹션에서 `fluid_name` 변수에 분석하고자 하는 유체의 이름을 문자열로 지정합니다. (예: `"N2O"`, `"CO2"`)
2.  **데이터 파일 준비**: 분석하려는 유체 이름과 동일한 이름의 엑셀 파일(예: `N2O.xlsx`, `CO2.xlsx`)이 스크립트와 같은 폴더 또는 MATLAB 경로 내에 있어야 합니다. 이 엑셀 파일에는 다음 두 개의 시트가 필요합니다:
    *   `<fluid_name>_saturation_liquid` (예: `N2O_saturation_liquid`): 액체 상태의 포화 데이터를 포함 (최소 온도, 압력, 밀도, 내부에너지, 엔탈피, 엔트로피, 정적비열, 정압비열, 음속 순서의 열 포함).
    *   `<fluid_name>_saturation_vapor` (예: `N2O_saturation_vapor`): 기체 상태의 포화 데이터를 포함 (액체 시트와 동일한 열 구조).
3.  **유체 클래스 준비**: 분석하려는 유체 이름과 동일한 이름의 `FluidEOS` 클래스를 상속받는 클래스 파일(예: `N2O.m`, `CO2.m`)이 `Props` 폴더 또는 MATLAB 경로 내에 정의되어 있어야 합니다.
4.  **스크립트 실행**: MATLAB에서 `plot_EOS.m` 스크립트를 실행합니다.
5.  **결과 확인**: 지정된 유체에 대한 물성치 비교 그래프가 생성됩니다. 각 서브플롯은 특정 물성치에 대해 EOS 계산 결과(마커)와 NIST 기준 데이터(실선)를 함께 보여줍니다.

# 전체 코드
```MATLAB
clc; clear; close all;

%% ---- 사용자 설정 ----
fluid_name = "N2O"; % 분석할 유체 이름 (예: "N2O", "CO2")
% --------------------

%% 1) Load NIST saturation data
filename = fluid_name + ".xlsx";
sheet_l = fluid_name + "_saturation_liquid";
sheet_v = fluid_name + "_saturation_vapor";

try
    L = readmatrix(filename, "Sheet", sheet_l);
    V = readmatrix(filename, "Sheet", sheet_v);
catch ME
    error('데이터 파일(%s) 또는 시트(%s, %s)를 찾을 수 없습니다. 파일 및 시트 이름을 확인하세요.\n오류 메시지: %s', ...
          filename, sheet_l, sheet_v, ME.message);
end

T_l        = L(:,1);    rho_l_NIST = L(:,3);    P_l_NIST   = L(:,2);
T_v        = V(:,1);    rho_v_NIST = V(:,3);    P_v_NIST   = V(:,2);

u_l_NIST   = L(:,5)*1e3; h_l_NIST = L(:,6)*1e3; s_l_NIST = L(:,7)*1e3;
cv_l_NIST  = L(:,8)*1e3; cp_l_NIST = L(:,9)*1e3; c_l_NIST = L(:,10);
u_v_NIST   = V(:,5)*1e3; h_v_NIST = V(:,6)*1e3; s_v_NIST = V(:,7)*1e3;
cv_v_NIST  = V(:,8)*1e3; cp_v_NIST = V(:,9)*1e3; c_v_NIST = V(:,10);

%% 2) Compute with EOS
try
    constructor_handle = str2func(fluid_name);
    fluid = constructor_handle();
catch ME
    error('유체 클래스(%s)를 생성할 수 없습니다. 클래스 이름 및 경로를 확인하세요.\n오류 메시지: %s', ...
          fluid_name, ME.message);
end

nL = numel(T_l);
nV = numel(T_v);
P_l_eos = NaN(nL,1); rho_l_sat = NaN(nL,1);
u_l_eos = NaN(nL,1); h_l_eos = NaN(nL,1); s_l_eos = NaN(nL,1);
cv_l_eos= NaN(nL,1); cp_l_eos= NaN(nL,1); c_l_eos = NaN(nL,1);
P_v_eos = NaN(nV,1); rho_v_sat = NaN(nV,1);
u_v_eos = NaN(nV,1); h_v_eos = NaN(nV,1); s_v_eos = NaN(nV,1);
cv_v_eos= NaN(nV,1); cp_v_eos= NaN(nV,1); c_v_eos = NaN(nV,1);

for i=1:nL
    H = fluid.computeState(T_l(i), rho_l_NIST(i));
    P_l_eos(i) = H.P/1e5;
    u_l_eos(i) = H.u; h_l_eos(i) = H.h; s_l_eos(i) = H.s;
    cv_l_eos(i)= H.cv; cp_l_eos(i)= H.cp; c_l_eos(i) = H.c;
    [rho_l_sat(i), ~] = fluid.satDensity(T_l(i));
end
for i=1:nV
    H = fluid.computeState(T_v(i), rho_v_NIST(i));
    P_v_eos(i) = H.P/1e5;
    u_v_eos(i) = H.u; h_v_eos(i) = H.h; s_v_eos(i) = H.s;
    cv_v_eos(i)= H.cv; cp_v_eos(i)= H.cp; c_v_eos(i) = H.c;
    [~, rho_v_sat(i)] = fluid.satDensity(T_v(i));
end

%% 3) All-in-one plot
figure_title = sprintf('%s: Saturation & Thermo Props', strrep(fluid_name,'_','\_'));
figure('Name', figure_title, 'NumberTitle','off','Position',[100 100 1000 800]);

% 1) Pressure vs T
subplot(4,2,1);
hold on;
plot(T_l, P_l_eos,'bd','MarkerSize',5);
plot(T_v, P_v_eos,'ro','MarkerSize',5);
plot(T_l, P_l_NIST,'b-','LineWidth',1.2);
plot(T_v, P_v_NIST,'r-','LineWidth',1.2);
hold off;
xlabel('T [K]'); ylabel('P [bar]');
title('Pressure vs T');
legend('EOS L','EOS V','NIST L','NIST V','Location','best');
grid on;

% 2) Density vs T
subplot(4,2,2);
hold on;
plot(T_l, rho_l_sat,'bd','MarkerSize',5);
plot(T_v, rho_v_sat,'ro','MarkerSize',5);
plot(T_l, rho_l_NIST,'b-','LineWidth',1.2);
plot(T_v, rho_v_NIST,'r-','LineWidth',1.2);
hold off;
xlabel('T [K]'); ylabel('\rho [kg/m^3]');
title('Saturation \rho vs T');
legend('satDensity L','satDensity V','NIST L','NIST V','Location','best');
grid on;

% 3–8) u,h / s,cv / cp,c
props   = {'u [J/kg]','h [J/kg]','s [J/(kg·K)]','c_v [J/(kg·K)]','c_p [J/(kg·K)]','c [m/s]'};
dataL_e = {u_l_eos, h_l_eos,   s_l_eos,   cv_l_eos,   cp_l_eos,   c_l_eos};
dataV_e = {u_v_eos, h_v_eos,   s_v_eos,   cv_v_eos,   cp_v_eos,   c_v_eos};
dataL_n = {u_l_NIST,h_l_NIST,  s_l_NIST,  cv_l_NIST,  cp_l_NIST,  c_l_NIST};
dataV_n = {u_v_NIST,h_v_NIST,  s_v_NIST,  cv_v_NIST,  cp_v_NIST,  c_v_NIST};

for k=1:6
    ax = subplot(4,2,2+k);
    hold on;
    plot(T_l, dataL_e{k}, 'bd','MarkerSize',4);
    plot(T_v, dataV_e{k}, 'ro','MarkerSize',4);
    plot(T_l, dataL_n{k}, 'b-','LineWidth',1.0);
    plot(T_v, dataV_n{k}, 'r-','LineWidth',1.0);
    hold off;
    xlabel('T [K]'); ylabel(props{k});
    title(props{k});
    legend('EOS L','EOS V','NIST L','NIST V','Location','best');
    grid on;
end

sgtitle_text = sprintf('%s Saturation & Thermo/Transport Properties', strrep(fluid_name,'_','\_'));
sgtitle(sgtitle_text);