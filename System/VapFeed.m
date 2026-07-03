function [x] = VapFeed(x)
%% Vapor Feed Simulation Step
% This function simulates one time step during the vapor feed phase when
% the run valve is open and vapor oxidizer is fed into the injector.
% It includes vapor venting, vapor injection, fuel regression, combustion,
% nozzle performance calculation, and tank state update.
% An iterative solver is used to find the steady-state combustion pressure (Pc).

%% Constants and Tolerances for Pc Iteration
MAX_ITER = 100; % Maximum iterations for Pc solver
TOL_PC = 1e-4;  % Relative tolerance for Pc convergence
RELAX_PC = 0.2; % Relaxation factor for Pc update

% --- Calculate Vent Mass Flow Rate (Calculated once, regardless of mode) ---
if x.vent.mode == 1
    if contains(x.vent.model, "ICF", "IgnoreCase", true)
        x = Vent_ICF(x);
    elseif contains(x.vent.model, "CdA", "IgnoreCase", true)
        x = Vent_CdA(x);
    else
        warning('VapFeed:UnknownVentModel', 'Unknown vent model: %s. No vent flow.', x.vent.model);
        x.vent.mdot = 0;
    end
else
    x.vent.mdot = 0;
end
% ----------------------------------------------------------

if x.test.mode == 1 % --- Combustion Test Mode Calculations ---

    %% Initial Guess for Pc
    Pc_guess = x.comb.P; % Use previous step's pressure

    %% Iterative Solver for Combustion Pressure (Pc)
    iter = 0;
    err_pc = 1;
    x_iter = x; % Use a temporary structure for iteration
    R_start_of_step = x_iter.fuel.R; % Store radius at the beginning of the step

    while err_pc > TOL_PC && iter < MAX_ITER
        iter = iter + 1;
        Pc_old = x_iter.comb.P; % Store Pc from the start of this iteration

        % --- Calculations INSIDE the Pc iteration loop --- 

        % 1. Vent calculation moved outside the loop

        % 2a. Calculate Injector Exit State (Vapor - based on current Pc guess)
        try
            x_iter = InjState_VapFeed(x_iter);
        catch ME
            warning('VapFeed:InjStateError', 'InjState_VapFeed failed at iter %d, Pc=%.2f Pa: %s. Aborting Pc loop.', iter, Pc_old, ME.message);
            x_iter.comb.P = Pc_old; % Revert to previous valid Pc
            break; % Exit the while loop
        end

        % 2b. Calculate Injector Mass Flow Rate (Vapor Phase)
        if Pc_old >= x_iter.tank.P
            warning('VapFeed:InjectorBackPressure', 'Pc (%.2f Pa) >= Tank P (%.2f Pa) at iter %d. Setting mdot_inj to 0.', Pc_old, x_iter.tank.P, iter);
            x_iter.inj.mdot = 0;
        else
            if contains(x_iter.inj.model_VapFeed, "NHNE", "IgnoreCase", true)
                 x_iter = Inj_NHNE_VapFeed(x_iter); % FML 증기상 유출 모델 (La Luna et al. 2022, 식 23)
            elseif contains(x_iter.inj.model_VapFeed, "CdA", "IgnoreCase", true)
                 x_iter = Inj_CdA_VapFeed(x_iter); % Assuming this exists
            elseif contains(x_iter.inj.model_VapFeed, "ICF", "IgnoreCase", true)
                 x_iter = Inj_ICF_VapFeed(x_iter);
            else
                error('VapFeed:UnknownInjectorModel', 'Unknown vapor injector model (expected NHNE, CdA or ICF): %s', x_iter.inj.model_VapFeed);
            end
        end

        % 3. Calculate Fuel Regression Rate and Mass Flow Rate (but don't update R permanently yet)
        if contains(x_iter.fuel.model, "aGn", "IgnoreCase", true)
            x_iter = Grain_aGn(x_iter);
            x_iter.fuel.R = R_start_of_step; % IMPORTANT: Reset radius to start-of-step value
        else
            error('VapFeed:UnknownFuelModel', 'Unknown fuel regression model: %s', x_iter.fuel.model);
        end

        % 4. Calculate Combustion Properties and *New* Pc
        x_iter = Comb_Itercalc(x_iter);
        Pc_new = x_iter.comb.P; % Get the newly calculated Pc

        % --- Check for convergence and update Pc guess --- 
        if isnan(Pc_new) || Pc_new <= 0
            warning('VapFeed:InvalidPcCalc', 'Combustion calculation resulted in invalid Pc (%.2f Pa) at iteration %d. Aborting Pc loop.', Pc_new, iter);
            x_iter.comb.P = Pc_old; % Revert to previous valid Pc or handle error
            break; % Exit the while loop
        end

        err_pc = abs(Pc_new - Pc_old) / Pc_new;
        Pc_next_iter = Pc_old + RELAX_PC * (Pc_new - Pc_old);
        x_iter.comb.P = Pc_next_iter;

    end % End of Pc iteration loop

    % Check if Pc solver converged
    if iter >= MAX_ITER
        warning('VapFeed:PcNotConverged', 'Pc solver did not converge within %d iterations. Last error: %.2e', MAX_ITER, err_pc);
    end
    % Assign results from the converged/last iteration state
    x = x_iter;

    % --- Update Grain Radius, dR_m, Ap, Ab for the completed step ---
    x = Update_GrainRadius(x);
    %-------------------------------------------------------------------------

    % 4.5. Calculate Combustion Chamber Parameters (mw, gamma, rho_c)
    x = Comb_param(x);

    % Calculate Acoustic Frequencies
    x = Comb_Frequency_LAM(x); % Calculate Longitudinal Acoustic Mode Frequencies
    x = Comb_Frequency_HM(x);  % Calculate Helmholtz Mode Frequencies
    x = Comb_Frequency_HLFM(x); % Calculate Hybrid Low Frequency Mode Frequency

    % 5. Calculate Nozzle Performance (Only in Combustion Mode)
    x = Nozzle(x);

else % --- Spray Test Mode Calculations (x.test.mode == 2) ---

    % Pc is already set to ambient in System.m

    % 2a. Calculate Injector Exit State (Vapor - using ambient backpressure)
    try
        x = InjState_VapFeed(x); % Pass the main x struct directly
    catch ME
        warning('VapFeed:InjStateErrorSpray', 'InjState_VapFeed failed in spray mode, Pc=%.2f Pa: %s', x.comb.P, ME.message);
        % Handle error appropriately, maybe set injector flow to zero?
        x.inj.mdot = 0;
    end

    % 2b. Calculate Injector Mass Flow Rate (Vapor Phase, using ambient backpressure)
    if x.comb.P >= x.tank.P % Should not happen if Pc = ambient
        warning('VapFeed:InjectorBackPressureSpray', 'Ambient Pc (%.2f Pa) >= Tank P (%.2f Pa)? Setting mdot_inj to 0.', x.comb.P, x.tank.P);
        x.inj.mdot = 0;
    elseif isfield(x.inj,'mdot') && x.inj.mdot ~= 0 % Check if not already set to 0 by error above
        if contains(x.inj.model_VapFeed, "NHNE", "IgnoreCase", true)
             x = Inj_NHNE_VapFeed(x); % FML 증기상 유출 모델 (La Luna et al. 2022, 식 23)
        elseif contains(x.inj.model_VapFeed, "CdA", "IgnoreCase", true)
             x = Inj_CdA_VapFeed(x);
        elseif contains(x.inj.model_VapFeed, "ICF", "IgnoreCase", true)
             x = Inj_ICF_VapFeed(x);
        else
            error('VapFeed:UnknownInjectorModelSpray', 'Unknown vapor injector model (expected NHNE, CdA or ICF): %s', x.inj.model_VapFeed);
        end
    end
    % No fuel regression, combustion, or nozzle calculations needed.
    % Unused outputs are set by System.m after this function returns.

end % End of if x.test.mode == 1

% --- Calculations OUTSIDE the mode check --- 

% 6. Update Tank State (Applies to both modes)
% Uses vent mdot (calculated before mode check) and inj mdot (calculated within mode check)
x = Tank_VapFeed(x); % Use the VapFeed tank update function

end 