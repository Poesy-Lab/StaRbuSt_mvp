function [x] = PreFeed(x)
%% PreFeed Simulation Step
% This function simulates the system state during the pre-feed phase,
% where only vapor vents from the tank and the run valve is closed.
% It selects the appropriate vent model based on input settings.

% 1. Calculate Vent Mass Flow Rate
if x.vent.mode == 1 % Check if venting is enabled
    % Select vent model based on the model string in x.vent.model
    % Assumes Init_Vent.m correctly stores "ICF" or "CdA" (or similar) string.
    if contains(x.vent.model, "ICF", "IgnoreCase", true)
        % Use Isentropic Choked Flow model
        x = Vent_ICF(x);
    elseif contains(x.vent.model, "CdA", "IgnoreCase", true)
        % Use CdA model
        x = Vent_CdA(x);
    else
        % Unknown model string specified in x.vent.model
        warning('Unknown vent model specified: %s. Assuming no vent flow.', x.vent.model);
        x.vent.mdot = 0;
        % Assign default critical/pressure ratios if needed downstream
        x.vent.ratio_Pcr = NaN; 
        x.vent.ratio_P = NaN;
    end
else
    % Venting is disabled
    x.vent.mdot = 0;
    % Assign default critical/pressure ratios if needed downstream
    x.vent.ratio_Pcr = NaN; 
    x.vent.ratio_P = NaN;
end

% 2. Update Tank State
% Calculates the next tank state considering the calculated vent mass flow (mdot_vent).
% Assumes Tank_PreFeed.m is in the path.
% CRITICAL: Assumes x contains the necessary x.fluid field for Tank_PreFeed.
x = Tank_PreFeed(x); % Tank_PreFeed uses x.vent.mdot internally

end 