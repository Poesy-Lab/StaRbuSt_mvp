function [x] = Vent_CdA(x)
%% Input
P_tank = x.tank.P;
P_amb = x.amb.P;
rhov = x.tank.rho_v;
A_vent = x.vent.A;
Cd_vent = x.vent.Cd;

%% System
deltaP = P_tank - P_amb;

if deltaP <= 0
    mdot_vent = 0;
else
    mdot_vent = Cd_vent * A_vent * sqrt(2 * rhov * deltaP);
end

%% Output
x.vent.mdot = mdot_vent;

end 