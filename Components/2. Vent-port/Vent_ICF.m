function [x] = Vent_ICF(x)
%% Input
P_tank = x.tank.P;
P_amb = x.amb.P;
rhov = x.tank.rho_v;
cpv = x.tank.cp_v;
cvv = x.tank.cv_v;
A_vent = x.vent.A;
Cd_vent = x.vent.Cd;

gamma = cpv / cvv;

%% System
% 임계 압력비 계산 (choked flow 조건)
critical_pressure_ratio = (2 / (gamma + 1))^(gamma / (gamma - 1));
pressure_ratio = P_amb / P_tank;

% 유량 계산
if pressure_ratio <= critical_pressure_ratio
    % 초크 유동
    mdot_vent = Cd_vent * A_vent * sqrt( ...
        gamma * P_tank * rhov * ...
        (2 / (gamma + 1))^((gamma + 1) / (gamma - 1)) );
else
    % 비초크 유동
    term1 = (P_amb / P_tank)^(2 / gamma);
    term2 = (P_amb / P_tank)^((gamma + 1) / gamma);
    mdot_vent = Cd_vent * A_vent * sqrt( ...
        (2 * gamma / (gamma - 1)) * rhov * P_tank * (term1 - term2) );
end

%% Output
x.vent.ratio_Pcr = critical_pressure_ratio;
x.vent.ratio_P = pressure_ratio;
x.vent.mdot = mdot_vent;

end 