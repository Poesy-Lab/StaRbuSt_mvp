---
tags:
  - 시스템
  - 액체 공급
  - 반복 계산
---
# 소개
- `LiqFeed.m`은 **런밸브가 열리고 탱크에서 액체 상태의 산화제가 인젝터로 공급되어 연소가 일어나는 단계**의 한 시간 스텝을 모사하는 함수입니다.
- 이 단계에서는 탱크 상단에서 증기상 유체가 벤트 포트로 유출되고, 탱크 하단에서 액체상 유체가 인젝터로 유출됩니다.
- 연소압(`Pc`)은 인젝터 유량, 연료 유량과 상호 의존적이므로, 함수 내부에 **반복 계산 루프**를 사용하여 해당 시간 스텝에서의 평형 연소압을 찾습니다.

# 시스템 계산 순서
1.  **연소압 초기 추정**: 이전 시간 스텝의 연소압(`x.comb.P`)을 현재 스텝의 연소압 초기 추정치로 사용합니다.
2.  **연소압 반복 계산 루프 시작**: 설정된 허용 오차(`TOL_PC`) 및 최대 반복 횟수(`MAX_ITER`) 내에서 다음 계산을 반복합니다.
    a.  **벤트 유량 계산**: 현재 상태(`x_iter`)를 기반으로 벤트 유량(`x_iter.vent.mdot`)을 계산합니다 (`Vent_ICF` 또는 `Vent_CdA` 호출, `x.vent.model` 기준). (주: 현재 구현에서는 루프 외부에서 한 번만 계산됩니다.)
    b.  **인젝터 출구 상태 계산**: 현재 연소압 추정치(`x_iter.comb.P`)를 사용하여 인젝터 출구의 상세 상태량 (`x_iter.inj.*`)을 계산합니다 (`InjState_LiqFeed` 호출).
    c.  **인젝터 유량 계산 (액체)**: 현재 연소압 추정치와 계산된 인젝터 출구 상태를 사용하여 인젝터 유량(`x_iter.inj.mdot`)을 계산합니다 (`Inj_CdA_LiqFeed` 또는 `Inj_NHNE_LiqFeed` 호출, `x.inj.model_LiqFeed` 기준).
    d.  **연료 유량 계산**: 계산된 인젝터 유량(`x_iter.inj.mdot`)을 사용하여 연료 유량(`x_iter.fuel.mdot`)을 계산합니다 (`Grain_aGn` 등 호출, `x.fuel.model` 기준). (주: 그레인 반지름은 이 단계에서 영구적으로 업데이트되지 않습니다.)
    e.  **연소 계산 및 새 연소압 계산**: 계산된 유량들과 현재 연소압 추정치(`x_iter.comb.P`)를 사용하여 특성 속도 및 **새로운 연소압**(`Pc_new`)을 계산합니다 (`Comb_Itercalc` 호출).
    f.  **수렴 확인 및 업데이트**: 새로 계산된 연소압(`Pc_new`)과 이전 연소압(`Pc_old`) 간의 상대 오차(`err_pc`)를 계산합니다. 오차가 허용 범위 내이면 루프를 종료합니다. 그렇지 않으면 다음 반복을 위해 연소압 추정치를 업데이트합니다 (`x_iter.comb.P = Pc_old + RELAX_PC * (Pc_new - Pc_old)`).
3.  **연소압 반복 계산 루프 종료**: 루프가 정상적으로 수렴했는지, 최대 반복 횟수를 초과했는지 확인하고 최종 연소압을 포함한 `x_iter`의 결과를 `x`에 할당합니다.
4.  **그레인 반지름 업데이트**: 확정된 유량 계산을 바탕으로 실제 그레인 반지름 변화를 계산하고 업데이트합니다 (`Update_GrainRadius` 호출).
5.  **연소실 파라미터 계산**: 확정된 연소압, O/F비 등을 사용하여 연소실의 주요 물성치(분자량 `mw`, 비열비 `gamma`, 밀도 `rho_c`)를 계산합니다 (`Comb_param` 호출). (이 단계는 `x.test.mode == 1`인 경우에만 수행됩니다.)
6.  **노즐 성능 계산**: 최종 연소압 및 연소 결과를 사용하여 추력 계수(`x.nozzle.Cf`)와 추력(`x.nozzle.F`)을 계산합니다 (`Nozzle` 호출). (이 단계는 `x.test.mode == 1`인 경우에만 수행됩니다.)
7.  **탱크 상태 업데이트**: 최종적으로 계산된 벤트 유량과 인젝터 유량 (마지막 반복 기준)을 사용하여 다음 시간 스텝의 탱크 상태 (`x.tank.*`)를 계산합니다 (`Tank_LiqFeed` 호출).

# Input

| 인수 | 설명                                                                                                  |
| ---- | ----------------------------------------------------------------------------------------------------- |
| `x`  | 현재 시간 스텝 시작 시점의 시스템 상태를 포함하는 구조체. 모든 컴포넌트의 상태 변수 및 설정을 포함해야 함. | 

# Output

| 반환값 | 설명                                                                                                                             | 
| ------ | -------------------------------------------------------------------------------------------------------------------------------- | 
| `x`    | 한 시간 스텝(`dt`) 동안의 계산이 완료된 후의 시스템 상태를 포함하는 구조체. 탱크 상태, 유량, 연소압, 추력 등이 업데이트됩니다. | 

# 전체 코드
```MATLAB
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
            if contains(x_iter.inj.model_LiqFeed, "CdA", "IgnoreCase", true)
                 x_iter = Inj_CdA_LiqFeed(x_iter);
            elseif contains(x_iter.inj.model_LiqFeed, "NHNE", "IgnoreCase", true)
                 x_iter = Inj_NHNE_LiqFeed(x_iter);
            else
                error('LiqFeed:UnknownInjectorModel', 'Unknown liquid injector model: %s', x_iter.inj.model_LiqFeed);
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
    elseif isfield(x.inj,'mdot') && x.inj.mdot ~= 0 % Check if not already set to 0 by error above
        if contains(x.inj.model_LiqFeed, "CdA", "IgnoreCase", true)
             x = Inj_CdA_LiqFeed(x);
        elseif contains(x.inj.model_LiqFeed, "NHNE", "IgnoreCase", true)
             x = Inj_NHNE_LiqFeed(x);
        else
            error('LiqFeed:UnknownInjectorModelSpray', 'Unknown liquid injector model: %s', x.inj.model_LiqFeed);
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