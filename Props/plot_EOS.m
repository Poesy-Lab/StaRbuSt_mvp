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