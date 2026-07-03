function [x] = Tank_PreFeed(x)
%% Input
fluid = x.fluid;
dt = x.time.dt;
m_tank = x.tank.m;
mdot_vent = x.vent.mdot;
V_tank = x.tank.V;
hv = x.tank.h_v;
H_tank = x.tank.H;

%% System

m_tank = m_tank - mdot_vent * dt;
rho_tank = m_tank / V_tank;

Hdot_vent = mdot_vent * hv;
H_tank = H_tank - Hdot_vent * dt;
h_tank = H_tank / m_tank;

% CoolProp 등 직접 rho-h 플래시 지원 모델이면 온도 역산(lsqnonlin) 대신 내장 플래시 사용
use_flash = ismethod(fluid, 'GetPropsDH');
if use_flash
    Props = fluid.GetPropsDH(rho_tank, h_tank);
    if Props.state == -1 || ~isfinite(Props.P)
        warning('Tank_PreFeed:FlashFail', 'GetPropsDH failed (rho=%.4g, h=%.4g). Falling back to lsqnonlin.', rho_tank, h_tank);
        use_flash = false;
    end
end
if ~use_flash
    % Determine initial guess for T_tank
    if isfield(x.tank, 'T') && ~isempty(x.tank.T) && isfinite(x.tank.T)
        T_guess = x.tank.T; % Use previous step's temperature as initial guess
    else
        T_guess = 300; % Fallback to 300 K if previous T is not available/valid
    end

    pFunc = @(T_unknown) getfield(fluid.GetProps(T_unknown, rho_tank), 'h') - h_tank;
    % Use T_guess as the initial guess in lsqnonlin
    T_tank = lsqnonlin(pFunc, T_guess, 0, Inf, optimset('Display', 'off', 'TolFun', 1e-10));
    Props = fluid.GetProps(T_tank, rho_tank);
end

%% Output
% 상태 변수
x.tank.state = Props.state; % -1: 오류, 0: 액체, 1: 포화, 2: 기체
x.tank.P = Props.P; % Pa
x.tank.T = Props.T; % K
x.tank.X = Props.X; % 건도
x.tank.m = m_tank; % Store updated total mass
% 액체 및 증기 질량 업데이트
x.tank.m_v = x.tank.m * x.tank.X;     % 증기 질량
x.tank.m_l = x.tank.m * (1 - x.tank.X); % 액체 질량

% 혼합물 물성
x.tank.rho = Props.rho; %kg/m^3
x.tank.u = Props.u; % J/kg
x.tank.s = Props.s; % J/kg-K
x.tank.h = Props.h; % J/kg
x.tank.cp = Props.cp; % J/kg-K
x.tank.cv = Props.cv; % J/kg-K
x.tank.c = Props.c; % m/s
x.tank.S = m_tank * Props.s; % J/K
x.tank.H = m_tank * Props.h; % J

% 증기상 물성
x.tank.rho_v = Props.rho_v; % kg/m^3
x.tank.u_v = Props.u_v; % J/kg
x.tank.s_v = Props.s_v; % J/kg-K
x.tank.h_v = Props.h_v; % J/kg
x.tank.cp_v = Props.cp_v; % J/kg-K
x.tank.cv_v = Props.cv_v; % J/kg-K
x.tank.c_v = Props.c_v; % m/s

% 액상 물성
x.tank.rho_l = Props.rho_l; % kg/m^3
x.tank.u_l = Props.u_l; % J/kg
x.tank.s_l = Props.s_l; % J/kg-K
x.tank.h_l = Props.h_l; % J/kg
x.tank.cp_l = Props.cp_l; % J/kg-K
x.tank.cv_l = Props.cv_l; % J/kg-K
x.tank.c_l = Props.c_l; % m/s

end 