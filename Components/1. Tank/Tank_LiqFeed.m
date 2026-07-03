function [x] = Tank_LiqFeed(x)
%% Input
fluid = x.fluid;
dt = x.time.dt;
m_tank = x.tank.m;
mdot_vent = x.vent.mdot;
V_tank = x.tank.V;
hv = x.tank.h_v;
H_tank = x.tank.H;
mdot_out = x.inj.mdot;
hl = x.tank.h_l;

%% System
m_tank = m_tank - ( mdot_vent + mdot_out ) * dt;
rho_tank = m_tank / V_tank;

Hdot_vent = mdot_vent * hv;
Hdot_out = mdot_out * hl;
H_tank = H_tank - ( Hdot_vent + Hdot_out ) * dt;
h_tank = H_tank / m_tank;

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

% Check if quality reached or exceeded 1 and clamp values
if Props.X >= 1
    Props.X = 1.0;     % Force quality to exactly 1
    Props.state = 2;   % Force state to vapor (2)
end

%% Output
% 상태 변수
x.tank.state = Props.state; % Use potentially clamped state
x.tank.P = Props.P; % Pa
x.tank.T = Props.T; % K
x.tank.X = Props.X; % Use potentially clamped quality
x.tank.m = m_tank; % <<< Store updated total mass
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
x.tank.S = m_tank * Props.s; % J/K
x.tank.H = m_tank * Props.h; % J

% 증기상 물성
x.tank.rho_v = Props.rho_v; % kg/m^3
x.tank.u_v = Props.u_v; % J/kg
x.tank.s_v = Props.s_v; % J/kg-K
x.tank.h_v = Props.h_v; % J/kg
x.tank.cp_v = Props.cp_v; % J/kg-K
x.tank.cv_v = Props.cv_v; % J/kg-K

% 액상 물성
x.tank.rho_l = Props.rho_l; % kg/m^3
x.tank.u_l = Props.u_l; % J/kg
x.tank.s_l = Props.s_l; % J/kg-K
x.tank.h_l = Props.h_l; % J/kg
x.tank.cp_l = Props.cp_l; % J/kg-K
x.tank.cv_l = Props.cv_l; % J/kg-K

end 