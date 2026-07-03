---
tags:
  - 시뮬레이션
  - 상태 업데이트
  - 증기 공급
Author: SRS 33기 박호진
lastmod: 2024-05-01 # 최종 수정일
---
# 소개
- `VapFeed.m`은 **증기 공급 단계(Vapor Feed Phase)** 에서 한 시간 스텝 동안 시스템 상태를 시뮬레이션하는 함수입니다. 탱크에 액체 산화제가 소진되고 증기만 남았을 때 활성화됩니다.
- 주요 기능은 `LiqFeed.m`과 유사하지만, **인젝터 관련 계산은 증기 상태**를 기준으로 수행합니다 (`InjState_VapFeed`, `Inj_CdA_VapFeed`, `Inj_ICF_VapFeed` 등 호출).
- `LiqFeed.m`과 동일하게 **Pc 반복 계산**, **그레인 반지름 업데이트 (`Update_GrainRadius` 호출)**, 노즐 계산, 탱크 상태 업데이트 (`Tank_VapFeed` 호출)를 포함합니다.
- **시험 모드(`x.test.mode`)** 에 따른 분기도 동일하게 적용됩니다.

# Input
- `x`: 현재 시스템 상태를 담고 있는 구조체 (`LiqFeed.m`과 동일한 필드 필요).

# System (Combustion Test Mode, `x.test.mode == 1` 기준)
1.  **벤트 유량 계산**: `Vent_ICF` 또는 `Vent_CdA` 호출 (루프 외부에서 한 번만 계산).
2.  **Pc 반복 계산 루프 시작**:
    1.  **인젝터 출구 상태 계산**: `InjState_VapFeed` 호출.
    2.  **인젝터 질량 유량 계산**: `Inj_CdA_VapFeed` 또는 `Inj_ICF_VapFeed` 호출.
    3.  **연료 후퇴율/유량 계산**: `Grain_aGn` 호출 (반지름 임시 고정).
    4.  **연소 계산 및 새 Pc 계산**: `Comb_Itercalc` 호출.
    5.  **수렴 확인 및 Pc 업데이트**.
3.  **Pc 반복 계산 루프 종료** 및 최종 상태 할당.
4.  **그레인 반지름 업데이트**: `Update_GrainRadius` 호출.
5.  **연소실 파라미터 계산**: `Comb_param` 호출 (확정된 Pc, OF 사용).
6.  **노즐 성능 계산**: `Nozzle` 호출.
7.  **탱크 상태 업데이트**: `Tank_VapFeed` 호출.

# Output
- `x`: 한 시간 스텝(`dt`) 동안 업데이트된 시스템 상태 구조체 (`LiqFeed.m`과 동일).

# 전체 코드
```MATLAB
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
            if contains(x_iter.inj.model_VapFeed, "CdA", "IgnoreCase", true)
                 x_iter = Inj_CdA_VapFeed(x_iter); % Assuming this exists
            elseif contains(x_iter.inj.model_VapFeed, "ICF", "IgnoreCase", true)
                 x_iter = Inj_ICF_VapFeed(x_iter);
            else
                error('VapFeed:UnknownInjectorModel', 'Unknown vapor injector model (expected CdA or ICF): %s', x_iter.inj.model_VapFeed);
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
        if contains(x.inj.model_VapFeed, "CdA", "IgnoreCase", true)
             x = Inj_CdA_VapFeed(x);
        elseif contains(x.inj.model_VapFeed, "ICF", "IgnoreCase", true)
             x = Inj_ICF_VapFeed(x);
        else
            error('VapFeed:UnknownInjectorModelSpray', 'Unknown vapor injector model (expected CdA or ICF): %s', x.inj.model_VapFeed);
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