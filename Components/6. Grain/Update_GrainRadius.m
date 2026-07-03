function [x] = Update_GrainRadius(x)
%Update_GrainRadius Updates the grain radius for the next time step.
%   Calculates the radius change based on the current regression rate and dt,
%   updates the radius for the next step (checking for burnout), and stores
%   the radius change (dR_m) and the areas (Ap, Ab) based on the radius
%   at the *start* of this time step.
%
% Inputs:
%   x: Structure containing current system state, must include:
%       x.fuel.rdot: Converged regression rate for the current step (mm/s)
%       x.time.dt: Time step (s)
%       x.fuel.R: Inner radius at the *start* of the current step (m)
%       x.fuel.R_out: Outer radius (m)
%       x.fuel.L: Grain length (m)
%
% Outputs:
%   x: Updated structure with:
%       x.fuel.R: Updated inner radius for the *next* time step (m)
%       x.fuel.dR_m: Change in radius during *this* time step (m)
%       Note: x.fuel.Ap and x.fuel.Ab are NOT set by this function.
%             They should be set by a function like Grain_aGn.m based on
%             the radius at the start of the step.

%% Input Extraction
rdot_final_mm_s = x.fuel.rdot; % Converged regression rate from the calling function
dt = x.time.dt;
R_current = x.fuel.R; % Radius at the start of the step
R_out = x.fuel.R_out;
L = x.fuel.L;

%% Calculate Radius Update
% Calculate the change for this dt based on the converged rate
dR_m_final = (rdot_final_mm_s * 1e-3) * dt; 
% Calculate the theoretical next radius
R_next_final = R_current + dR_m_final;

% Check for fuel burnout
if R_next_final >= R_out
    R_next_final = R_out; % Cap the radius
    % Calculate the actual change applied if capped
    dR_m_final = max(0, R_out - R_current); 
    % Note: rdot might have been non-zero to cause this, but for the next step,
    % the radius is capped. The stored rdot reflects the rate *during* the step.
end

%% Calculate Areas based on STARTING Radius - REMOVED
% These areas (Ap_current, Ab_current) are now assumed to be calculated and set 
% by other functions (e.g., Grain_aGn.m) using the radius at the start of the step.
% Ap_current = pi * R_current^2; 
% Ab_current = 2 * pi * R_current * L;

%% Update Output Structure
% Store the radius for the NEXT step
x.fuel.R = R_next_final; 
% Store the change that occurred IN this step
x.fuel.dR_m = dR_m_final; 
% x.fuel.Ap and x.fuel.Ab are no longer set here.

end 