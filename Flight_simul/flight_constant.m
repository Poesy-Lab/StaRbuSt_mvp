function out = flight_constant()

persistent constant

if isempty(constant)
    % Earth Constants
    constant.Earth_center = [0; 0; 0]; % Earth's center position
    constant.R_e = 6370.2e3; % Earth radius at seoul (h=0 in WGS84) (m)
    constant.M_e = 5.9742e24; % Earth mass (kg)
    constant.G = 6.673e-11; % Gravitational constant (m^3 kg^-1 s^-2)
    constant.g_0 = constant.G*constant.M_e/constant.R_e^2; % Gravitational Acceleration (sea level);
    constant.rho_sea = 1.2;
    constant.R_air = 287.058;
end

out = constant;
    
end