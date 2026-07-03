function [x] = Grain_aGn(x)
% Grain_aGn Calculates instantaneous fuel regression rate, mass flow, and areas
%           based on the a*G^n model using the current grain radius.
%
% Inputs:
%   x: Structure containing current system state, must include:
%       x.inj.mdot: Oxidizer mass flow rate (kg/s)
%       x.fuel.N: Number of ports
%       x.fuel.R: Current inner radius (m)
%       x.fuel.L: Grain length (m)
%       x.fuel.a: Regression rate coefficient a
%       x.fuel.n: Regression rate exponent n
%       x.fuel.rho: Fuel density (kg/m^3)
%       x.fuel.R_out: Outer radius (m) - Needed for burnout check
%
% Outputs:
%   x: Updated structure with instantaneous values based on input x.fuel.R:
%       x.fuel.Gox: Oxidizer mass flux (kg/m^2-s)
%       x.fuel.rdot: Regression rate (mm/s)
%       x.fuel.mdot: Fuel mass flow rate (kg/s)
%       x.fuel.Ap: Port area based on current radius (m^2)
%       x.fuel.Ab: Burn area based on current radius (m^2)
% Note: This function DOES NOT update x.fuel.R for the next time step.
%       Time integration must be handled by the calling function.

%% Input Extraction
mdot_ox = x.inj.mdot;
N = x.fuel.N;
R_current = x.fuel.R; % Use current radius for this step's calculations
L = x.fuel.L;
a = x.fuel.a;
n = x.fuel.n;
rho_f = x.fuel.rho;
% dt is no longer needed here
R_out = x.fuel.R_out; % Needed for potential burnout impact on rates

%% Calculations based on Current Radius

% Check for burnout condition based on input radius first
if R_current >= R_out
    % If already burned out at the start of this calculation
    Gox = 0;
    rdot_mm_s = 0;
    mdot_f = 0;
    Ap = pi * R_current^2; % Area still exists
    Ab = 0; % No burn area if already burned out
    % fprintf('Grain already burned out at R=%.4f >= R_out=%.4f\n', R_current, R_out);
elseif mdot_ox <= 0 % Also check if there is any oxidizer flow
    Gox = 0;
    rdot_mm_s = 0;
    mdot_f = 0;
    Ap = pi * R_current^2;
    Ab = 2 * pi * R_current * L;
else
    % Normal calculation if not burned out and oxidizer flows
    Ap = pi * R_current^2; % Port area based on current radius
    Ab = 2 * pi * R_current * L; % Burn area based on current radius

    % Oxidizer mass flux
    Gox = mdot_ox / (N * Ap); % kg/m^2*s

    % Regression rate
    rdot_mm_s = a * Gox^n; % mm/s

    % Calculate fuel mass flow rate
    mdot_f = ( rdot_mm_s * 1e-3 ) * ( N * Ab ) * rho_f; % kg/s
end

%% Output Update (Instantaneous values based on R_current)
x.fuel.Gox = Gox;
x.fuel.rdot = rdot_mm_s; % Output regression rate calculated with R_current
x.fuel.mdot = mdot_f;    % Output fuel mass flow rate calculated with R_current
x.fuel.Ap = Ap;          % Output port area calculated with R_current
x.fuel.Ab = Ab;          % Output burn area calculated with R_current
% x.fuel.R is NOT updated here
% x.fuel.dR_m is NOT calculated or updated here

end 