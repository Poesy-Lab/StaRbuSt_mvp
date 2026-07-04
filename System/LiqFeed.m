function [x] = LiqFeed(x)
%% Liquid Feed Simulation Step
% This function simulates one time step during the liquid feed phase.
% It includes vapor venting, liquid injection, fuel regression, combustion,
% nozzle performance calculation, and tank state update.
% An iterative solver is used to find the steady-state combustion pressure (Pc).

%% Constants and Tolerances for Pc Iteration
MAX_ITER = 200; % Maximum iterations for Pc solver (Reverted from 300)
TOL_PC = 5e-4;  % Relative tolerance for Pc convergence (Reverted from 2e-3)
RELAX_PC = 0.3; % Relaxation factor for Pc update (Increased from 0.2)

% --- Calculate Vent Mass Flow Rate (Calculated once, regardless of mode) ---
if x.vent.mode == 1
    if contains(x.vent.model, "ICF", "IgnoreCase", true)
        x = Vent_ICF(x);
    elseif contains(x.vent.model, "CdA", "IgnoreCase", true)
        x = Vent_CdA(x);
    else
        warning('LiqFeed:UnknownVentModel', 'Unknown vent model: %s. No vent flow.', x.vent.model);
        x.vent.mdot = 0;
    end
else
    x.vent.mdot = 0;
end
% ----------------------------------------------------------

if x.test.mode == 1 % --- Combustion Test Mode Calculations ---

    %% Initial Guess for Pc
    % Use the combustion pressure from the previous time step as the initial guess
    Pc_guess = x.comb.P; % Use previous step's pressure

    %% Iterative Solver for Combustion Pressure (Pc)
    iter = 0;
    err_pc = 1;
    x_iter = x; % Use a temporary structure for iteration to preserve original x if needed
    R_start_of_step = x_iter.fuel.R; % Store radius at the beginning of the step

    while err_pc > TOL_PC && iter < MAX_ITER
        iter = iter + 1;
        Pc_old = x_iter.comb.P; % Store Pc from the start of this iteration

        % --- Calculations INSIDE the Pc iteration loop --- 
        
        % 1. Vent calculation moved outside the loop
        
        % 2a. Calculate Injector Exit State (based on current Pc guess)
        try
            x_iter = InjState_LiqFeed(x_iter);
        catch ME
            warning('LiqFeed:InjStateError', 'InjState_LiqFeed failed at iter %d, Pc=%.2f Pa: %s. Aborting Pc loop.', iter, Pc_old, ME.message);
            x_iter.comb.P = Pc_old; % Revert to previous valid Pc
            break; % Exit the while loop
        end

        % 2b. Calculate Injector Mass Flow Rate (Liquid Phase)
        if Pc_old >= x_iter.tank.P
            warning('LiqFeed:InjectorBackPressure', 'Pc (%.2f Pa) >= Tank P (%.2f Pa) at iter %d. Setting mdot_inj to 0.', Pc_old, x_iter.tank.P, iter);
            x_iter.inj.mdot = 0;
        else
            if contains(x_iter.inj.model_LiqFeed, "HEMc", "IgnoreCase", true)
                 x_iter = Inj_HEMc_LiqFeed(x_iter); % 2상 입구 HEM_c (+급기 라인 결합, x.feed.mode=1 시)
            elseif contains(x_iter.inj.model_LiqFeed, "FML", "IgnoreCase", true)
                 x_iter = Inj_FML_LiqFeed(x_iter); % 보이드율 가중 FML 모델 (La Luna et al. 2022, 식 22)
            elseif contains(x_iter.inj.model_LiqFeed, "CdA", "IgnoreCase", true)
                 x_iter = Inj_CdA_LiqFeed(x_iter);
            elseif contains(x_iter.inj.model_LiqFeed, "NHNE", "IgnoreCase", true)
                 x_iter = Inj_NHNE_LiqFeed(x_iter);
            else
                error('LiqFeed:UnknownInjectorModel', 'Unknown liquid injector model (expected HEMc, FML, CdA or NHNE): %s', x_iter.inj.model_LiqFeed);
            end
        end
        
        % 3. Calculate Fuel Regression Rate and Mass Flow Rate (but don't update R permanently yet)
        if contains(x_iter.fuel.model, "aGn", "IgnoreCase", true)
            x_iter = Grain_aGn(x_iter);
            x_iter.fuel.R = R_start_of_step; % IMPORTANT: Reset radius to start-of-step value
        else
            error('LiqFeed:UnknownFuelModel', 'Unknown fuel regression model: %s', x_iter.fuel.model);
        end

        % 4. Calculate Combustion Properties and *New* Pc
        x_iter = Comb_Itercalc(x_iter);
        Pc_new = x_iter.comb.P; % Get the newly calculated Pc

        % --- Check for convergence and update Pc guess --- 
        if isnan(Pc_new) || Pc_new <= 0
            warning('LiqFeed:InvalidPcCalc', 'Combustion calculation resulted in invalid Pc (%.2f Pa) at iteration %d. Aborting Pc loop.', Pc_new, iter);
            x_iter.comb.P = Pc_old; % Revert to previous valid Pc or handle error
            break; % Exit the while loop
        end

        err_pc = abs(Pc_new - Pc_old) / Pc_new;
        Pc_next_iter = Pc_old + RELAX_PC * (Pc_new - Pc_old);
        x_iter.comb.P = Pc_next_iter;

        % Pinj도 이완된 Pc와 일관되게 갱신 (Pinj = ratio * Pc)
        % 인젝터가 읽는 하류압(Pinj)을 무감쇠로 두면 초크 경계 부근에서
        % (dmdot/dPinj 큰 비초크 분기) 고정점 반복이 발산할 수 있다.
        if isfinite(x_iter.comb.Pinj) && x_iter.comb.Pinj > 0
            x_iter.comb.Pinj = (x_iter.comb.Pinj / Pc_new) * Pc_next_iter;
        end

    end % End of Pc iteration loop

    % Check if Pc solver converged
    if iter >= MAX_ITER
        warning('LiqFeed:PcNotConverged', 'Pc solver did not converge within %d iterations. Last error: %.2e', MAX_ITER, err_pc);
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
    
    % 2a. Calculate Injector Exit State (using ambient backpressure)
    try
        x = InjState_LiqFeed(x); % Pass the main x struct directly
    catch ME
        warning('LiqFeed:InjStateErrorSpray', 'InjState_LiqFeed failed in spray mode, Pc=%.2f Pa: %s', x.comb.P, ME.message);
        % Handle error appropriately, maybe set injector flow to zero?
        x.inj.mdot = 0;
    end

    % 2b. Calculate Injector Mass Flow Rate (Liquid Phase, using ambient backpressure)
    if x.comb.P >= x.tank.P % Should not happen if Pc = ambient
        warning('LiqFeed:InjectorBackPressureSpray', 'Ambient Pc (%.2f Pa) >= Tank P (%.2f Pa)? Setting mdot_inj to 0.', x.comb.P, x.tank.P);
        x.inj.mdot = 0;
    elseif contains(x.inj.model_LiqFeed, "HEMc", "IgnoreCase", true)
        % HEMc는 InjState 결과/직전 유량에 의존하지 않으므로 항상 호출
        % (직전 스텝 유량 0에 의한 래치 방지)
        x = Inj_HEMc_LiqFeed(x); % 2상 입구 HEM_c (+급기 라인 결합, x.feed.mode=1 시)
    elseif isfield(x.inj,'mdot') && x.inj.mdot ~= 0 % Check if not already set to 0 by error above
        if contains(x.inj.model_LiqFeed, "FML", "IgnoreCase", true)
             x = Inj_FML_LiqFeed(x); % 보이드율 가중 FML 모델 (La Luna et al. 2022, 식 22)
        elseif contains(x.inj.model_LiqFeed, "CdA", "IgnoreCase", true)
             x = Inj_CdA_LiqFeed(x);
        elseif contains(x.inj.model_LiqFeed, "NHNE", "IgnoreCase", true)
             x = Inj_NHNE_LiqFeed(x);
        else
            error('LiqFeed:UnknownInjectorModelSpray', 'Unknown liquid injector model (expected HEMc, FML, CdA or NHNE): %s', x.inj.model_LiqFeed);
        end
    end
    % No fuel regression, combustion, or nozzle calculations needed.
    % Unused outputs are set by System.m after this function returns.

end % End of if x.test.mode == 1

% --- Calculations OUTSIDE the mode check --- 

% 6. Update Tank State (Applies to both modes)
% Uses vent mdot (calculated before mode check) and inj mdot (calculated within mode check)
x = Tank_LiqFeed(x);

end 