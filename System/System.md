---
tags:
  - 시스템
  - 메인 루프
  - 시뮬레이션 제어
  - 상태 관리
---
# 소개
- `System.m` 함수는 전체 시뮬레이션 타임라인을 실행하는 메인 컨트롤러입니다.
- `Input.m`으로부터 초기화된 시스템 상태 구조체 `x`를 입력받아, 시간의 흐름에 따라 각기 다른 작동 단계(Phase)에 해당하는 함수들(`PreFeed`, `LiqFeed`, `VapFeed`)을 적절히 호출합니다.
- 시뮬레이션 진행 중 주요 변수들의 시간에 따른 변화를 기록하여 결과 구조체 `y`를 반환합니다.

# 주요 기능 및 실행 순서

1.  **초기화 (`Initialization`)**:
    -   `x.flags.X_transition_handled` 플래그가 없으면 `false`로 초기화합니다. 이 플래그는 액상에서 기상으로의 전환(X=1 도달) 시 외삽(extrapolation) 로직이 한 번만 실행되도록 관리합니다.
    -   시뮬레이션 총 시간 스텝 수 (`num_steps`)를 `x.time.start`, `x.time.stop`, `x.time.dt`를 이용해 계산합니다.
    -   `fields_to_log` 셀 배열에 기록할 주요 변수들의 목록을 정의합니다. (예: `amb.P`, `tank.T`, `inj.mdot` 등)
    -   `initialize_history` 헬퍼 함수를 호출하여 `num_steps` 크기만큼의 NaN 또는 빈 문자열로 채워진 결과 저장용 구조체 `y`를 미리 할당합니다.
    -   현재 시뮬레이션 시간 `time_current`를 `x.time.start`로, `x.time.current`를 현재 시간으로 초기화합니다.
    -   시뮬레이션 시작 메시지를 출력하고, 진행 상황 업데이트를 위한 `next_update_time`을 설정합니다.

2.  **메인 시뮬레이션 루프 (`Simulation Loop`)**: `k = 1`부터 `num_steps`까지 다음을 반복합니다.
    a.  **진행 상황 업데이트**: 매 1초 간격으로 현재 시뮬레이션 시간을 콘솔에 출력합니다.
    b.  **종료 조건 확인**: `time_current`가 `x.time.stop`에 도달하면 루프를 중단합니다.
    c.  **분무 시험 모드 처리**: `x.test.mode == 2` (분무 시험)인 경우, 연소실 압력(`x.comb.P`)을 현재 단계 계산 전에 대기압(`x.amb.P`)으로 설정합니다. 연소 시험 모드에서는 `Comb_Itercalc` 등에서 연소압이 계산됩니다.
    d.  **단계 선택 (`Phase Selection`)**:
        -   **PreFeed 단계**: `time_current`가 연소 시작 시간(`x.time.run`)보다 (작은 오차를 감안하여) 이전이면, `PreFeed(x)` 함수를 호출합니다.
            -   이 단계에서는 연소기 온도 및 인젝터 온도를 대기 온도로, 연소기 입구 압력(`Pinj`)을 대기압으로 설정합니다.
            -   `set_unused_outputs(x, 'PreFeed')`를 호출하여 이 단계에서 사용되지 않는 다른 컴포넌트의 출력값들을 NaN 또는 0으로 설정합니다.
        -   **LiqFeed 단계**: 탱크 내 유체가 액상 또는 이상(two-phase) 상태(`x.tank.state == 0 || x.tank.state == 1`)이고 `x.flags.X_transition_handled`가 `false`이면, `LiqFeed(x)` 함수를 호출합니다.
            -   **액체 고갈 및 외삽 처리**: `LiqFeed` 호출 후 탱크 건도(`x.tank.X`)가 1 이상이 되고 `x.flags.X_transition_handled`가 `false`이면, 액체가 모두 기화된 것으로 간주하고 외삽 로직을 수행합니다.
                -   이전 시간 스텝들(`1` 부터 `k-1`까지)의 데이터를 사용하여 건도 X=1이 되는 정확한 시간(`extrapolated_time`)을 `interp1` 함수로 외삽합니다.
                -   외삽된 시간을 기준으로 다른 모든 주요 변수들도 외삽하여 현재 스텝(`k`)의 상태 `x`를 업데이트합니다.
                -   `x.flags.X_transition_handled`를 `true`로 설정하여 외삽이 반복되지 않도록 합니다.
                -   탱크 상태 `x.tank.state`를 2 (기상)로 명시적으로 변경하고, `time_current`를 외삽된 시간으로 업데이트합니다.
                -   외삽에 실패하거나 데이터가 부족하면 경고를 표시하고 최소한의 처리(X=1, state=2 설정)를 합니다.
            -   `LiqFeed` 함수 내에서 오류 발생 시, 에러 메시지를 출력하고 시뮬레이션을 중단합니다.
        -   **VapFeed 단계**: 탱크가 기상 상태(`x.tank.state == 2`)이거나 `x.flags.X_transition_handled`가 `true`(즉, LiqFeed에서 기상으로 전환됨)이면, `VapFeed(x)` 함수를 호출합니다.
            -   `set_unused_outputs(x, 'VapFeed')`를 호출하여 이 단계에 맞게 사용되지 않는 출력들을 처리합니다.
            -   VapFeed 중에는 인젝터의 NHNE 모델 관련 유량(`mdot_inc`, `mdot_HEM`)을 0으로 설정합니다.
            -   `VapFeed` 함수 내에서 오류 발생 시, 에러 메시지를 출력하고 시뮬레이션을 중단합니다.
        -   **종료/오류 단계**: 위의 조건에 해당하지 않으면 (예: 탱크 상태가 -1), 유량을 모두 0으로 설정하고 관련 없는 출력들을 정리한 후 루프를 중단합니다.
    e.  **분무 시험 모드 후처리**: 단계 계산 후, `x.test.mode == 2`이면 `set_unused_outputs(x, 'SprayTest')`를 호출하여 연료, 연소(압력 제외), 노즐 관련 출력들을 NaN/0으로 설정합니다.
    f.  **저압 종료 조건 확인**:
        -   탱크 압력(`x.tank.P`)이 대기압(`x.amb.P`)보다 낮아지면 시뮬레이션을 중단합니다.
        -   연소 시험 모드(`x.test.mode == 1`)에서 연소실 압력(`x.comb.P`)이 대기압보다 낮아지면 시뮬레이션을 중단합니다.
    g.  **상태 기록**: 현재 시간 스텝(`k`)의 계산된 상태 `x`를 `store_state` 헬퍼 함수를 통해 결과 구조체 `y`에 저장합니다.
    h.  **시간 업데이트**: `time_current`를 `x.time.dt`만큼 증가시키고, `x.time.current`도 업데이트하여 다음 스텝을 준비합니다.

3.  **시뮬레이션 루프 종료 후 처리**:
    -   실제로 실행된 스텝 수(`last_valid_index = k - 1`)를 기준으로 결과 구조체 `y`의 모든 필드를 잘라내어(trim) 불필요하게 할당된 NaN 값을 제거합니다.
    -   만약 루프가 한 스텝도 실행되지 않았다면 경고를 표시하고 빈 결과 구조체를 반환합니다.
    -   시뮬레이션 종료 메시지를 출력합니다.
    -   (주석 처리된 부분: 최종 결과 `y`에 남아있는 NaN 값을 플롯팅을 위해 0으로 대체하는 로직)

# Input

| 인수 | 설명                                                                 |
| ---- | -------------------------------------------------------------------- |
| `x`  | `Input.m` 함수로부터 반환된, 시뮬레이션 시작 시점의 모든 컴포넌트에 대한 초기 상태 및 설정을 포함하는 구조체. | 

# Output

| 반환값 | 설명                                                                                                                               |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `y`    | 시뮬레이션 동안 각 시간 스텝별로 `fields_to_log`에 정의된 모든 주요 변수들의 값의 히스토리를 저장한 구조체. `y.time`은 시간 벡터를 포함합니다. | 

# Helper Functions

-   **`initialize_history(num_steps, fields_to_log)`**: 결과 저장용 구조체 `y`를 사전 할당하고 NaN 또는 빈 문자열로 초기화합니다.
-   **`store_state(y, x, k, fields_to_log)`**: 현재 스텝 `k`의 상태 `x`를 `y` 구조체에 기록합니다.
-   **`set_unused_outputs(x, phase)`**: 현재 시뮬레이션 단계(`phase`)에 따라 사용되지 않는 `x` 구조체의 필드들을 NaN 또는 0으로 설정합니다.
-   **`fill_remaining_nan(y, start_index, end_index, fields_to_log)`**: 시뮬레이션 조기 종료 시, `y` 구조체의 남은 부분을 NaN으로 채웁니다.
-   (주석 처리된 `GetStateFromHistory`는 특정 시점의 상태를 `y`로부터 추출하는 함수로 보입니다.) 

# 전체 코드
```MATLAB
function [y] = System(x)
%% Main System Simulation Function
% This function runs the entire simulation timeline, calling appropriate
% phase functions (PreFeed, LiqFeed, VapFeed) based on time and state.
% Input: x - Initial state structure from Input function.
% Output: y - Structure containing the time history of key variables.

% --- Ensure X_transition_handled flag exists ---
if ~isfield(x, 'flags') || ~isfield(x.flags, 'X_transition_handled')
    x.flags.X_transition_handled = false;
    % fprintf('Initializing x.flags.X_transition_handled to false.\\n'); % Optional debug message
end
% --- End flag check ---

%% Initialization
% Calculate total number of steps
num_steps = round((x.time.stop - x.time.start) / x.time.dt) + 1;

% Define fields to log (excluding time, handled separately)
fields_to_log = {...
    'amb',  {'P', 'T', 'g'}, ...
    'tank', {'P', 'T', 'rho', 'm', 'state', 'X', 'A', ...
             'm_v', 'm_l', ...
             'u', 'u_v', 'u_l', ...
             's', 's_v', 's_l', ...
             'h', 'h_v', 'h_l', ...
             'cp', 'cp_v', 'cp_l', ...
             'cv', 'cv_v', 'cv_l', ...
             'H', 'S', 'rho_v', 'rho_l', ...
             'kappa', 'mdot_inc', 'mdot_HEM', ...
             'ratio_Pcr', 'ratio_P'}, ...
    'vent', {'mdot', 'ratio_Pcr', 'ratio_P'}, ...
    'inj',  {'mdot', 'P', 'T', 'rho', 'state', 'X', ...
             'u', 'u_v', 'u_l', ...
             's', 's_v', 's_l', ...
             'h', 'h_v', 'h_l', ...
             'cp', 'cp_v', 'cp_l', ...
             'cv', 'cv_v', 'cv_l', ...
             'rho_v', 'rho_l', ...
             'kappa', 'mdot_inc', 'mdot_HEM', ...
             'ratio_Pcr', 'ratio_P'}, ...
    'fuel', {'Gox', 'rdot', 'mdot', 'R_out', 'R', 'Ap', 'Ab', 'dR_m'}, ...
    'comb', {'mdot', 'OF', 'cstar', 'P', 'T', 'eta', 'fac_CR', 'Pinj'}, ...
    'nozzle', {'Cf', 'F', 'Isp_sl', 'Mode', 'Pe', 'mw', 'gamma', 'rho_c', 'Pt'} ...
    };

% Pre-allocate history structure 'y' for efficiency
y = initialize_history(num_steps, fields_to_log);

% Simulation Loop Setup
time_current = x.time.start;
x.time.current = time_current; % Initialize current time in x

%% Simulation Start Message and Progress Tracking
fprintf('Simulation started (Max time: %.2f s)...\n', x.time.stop);
next_update_time = floor(x.time.start) + 1.0;

%% Simulation Loop
for k = 1:num_steps
    % --- Add Debug Print ---
    % fprintf('DEBUG: Start of loop k=%d, t=%.4f, x.tank.state=%.0f, x.tank.X=%.4f\n', k, time_current, x.tank.state, x.tank.X);
    % --- End Add Debug Print ---

    % --- Progress Update ---
    if time_current >= next_update_time
        fprintf('Simulation progress: t = %.2f s / %.2f s\n', next_update_time, x.time.stop);
        next_update_time = next_update_time + 1.0;
    end
    % --- End Progress Update ---

    % --- Check stop time condition first ---
    if time_current >= x.time.stop
         % fprintf('Breaking loop at k = %d because time_current (%.4f) >= x.time.stop (%.4f)\\n', k, time_current, x.time.stop); % Debug print (if needed) (Removed)
         break;
    end

    % --- Set Combustor Pressure based on Test Mode ---
    if x.test.mode == 2 % Spray Test Mode
        x.comb.P = x.amb.P; % Set backpressure to ambient before calculations
    end
    % In Combustion Test Mode (x.test.mode == 1), Pc is calculated by Comb later

    % --- Phase Selection --- 
    if time_current < (x.time.run - x.time.dt / 10) % Use tolerance for PreFeed end
        % --- PreFeed Phase ---
        x = PreFeed(x);
        % Set specific temperatures to ambient during PreFeed
        if isfield(x, 'amb') && isfield(x.amb, 'T')
             if isfield(x, 'comb')
                 x.comb.T = x.amb.T;
             end
             if isfield(x, 'inj')
                 x.inj.T = x.amb.T;
             end
        else 
            warning('System:AmbTNotFound', 'Ambient temperature (x.amb.T) not found during PreFeed.');
        end
        % Set Pinj to ambient pressure during PreFeed
        if isfield(x, 'amb') && isfield(x.amb, 'P')
            if isfield(x, 'comb')
                x.comb.Pinj = x.amb.P; % Set Pinj to Pamb
            else
                x.comb = struct(); % Ensure comb struct exists
                x.comb.Pinj = x.amb.P; % Set Pinj to Pamb
            end
        else
            warning('System:AmbPNotFound', 'Ambient pressure (x.amb.P) not found during PreFeed for Pinj.');
            if isfield(x, 'comb')
                x.comb.Pinj = NaN; % Set to NaN if Pamb not found
            else
                x.comb = struct();
                x.comb.Pinj = NaN;
            end
        end
        % Set other unused outputs to NaN or zero if applicable
        x = set_unused_outputs(x, 'PreFeed');

    elseif (x.tank.state == 0 || x.tank.state == 1) && ~x.flags.X_transition_handled % Check time AND presence of liquid AND X_transition_handled is false for LiqFeed
        % --- Liquid Feed Phase ---
        try
            x = LiqFeed(x); % Calculate LiqFeed state (uses Pc set above if spray mode)

            % --- Check if tank is now vapor-only (Transition check) ---
            % --- Run extrapolation ONLY if X>=1 AND it hasn't been handled yet ---
            if isfield(x.tank,'X') && x.tank.X >= 1 && ~x.flags.X_transition_handled
                 fprintf('\n>>> X >= 1 detected for the first time at k=%d (t=%.4f s). Attempting extrapolation...\n', k, time_current);

                 % --- Extrapolate using data ONLY from previous steps (1 to k-1) ---
                 if k >= 3 % Need at least two previous points (k-1 and k-2) for extrapolation
                     X_query = 1.0;
                     option = 'spline';
                     extrapolation_successful = false; % Flag to track success
                     
                     % Get indices for history data (up to k-1)
                     hist_indices = 1:(k-1);

                     % --- Step 1: Extrapolate Time based on X --- 
                     try
                         % Find valid indices where both X and time are not NaN in history
                         valid_X_time_indices = hist_indices(~isnan(y.tank.X(hist_indices)) & ~isnan(y.time(hist_indices)));

                         if length(valid_X_time_indices) >= 2
                             X_hist = y.tank.X(valid_X_time_indices);
                             time_hist = y.time(valid_X_time_indices);

                             if length(unique(X_hist)) >= 2 % Need distinct X values
                                 extrapolated_time = interp1(X_hist, time_hist, X_query, option, 'extrap');
                                 fprintf('    Step 1: Extrapolated time for X=1 is %.4f s (using data up to k=%d).\n', extrapolated_time, k-1);
                                 extrapolation_successful = true; % Mark step 1 as successful
                             else
                                 fprintf('    Warning (Step 1): Not enough distinct X values in history up to k=%d to extrapolate time.\n', k-1);
                             end
                         else
                             fprintf('    Warning (Step 1): Not enough valid (X, time) pairs (found %d) in history up to k=%d to extrapolate time.\n', length(valid_X_time_indices), k-1);
                         end
                     catch ME_time_extrap
                         fprintf('    Warning (Step 1): Time extrapolation failed at k=%d (using data up to k=%d). Error: %s.\n', k, k-1, ME_time_extrap.message);
                     end
                     % --- End Step 1 --- 

                     % --- Step 2 & 3: Extrapolate all other variables based on Time & Update x ---
                     if extrapolation_successful % Proceed only if time extrapolation was successful
                         original_x = x; % Keep a copy of the originally calculated x for fallback
                         x.time.current = extrapolated_time;
                         x.tank.X = X_query; % Set X directly

                         % Loop through all fields defined in fields_to_log
                         fields_i = 1;
                         while fields_i <= length(fields_to_log)
                             component_name = fields_to_log{fields_i};
                             field_names = fields_to_log{fields_i+1};
                             
                             if isfield(x, component_name) % Check if component exists in x
                                 for fields_j = 1:length(field_names)
                                     field_name = field_names{fields_j};

                                     % Skip time (already done) and tank.X (set directly)
                                     if strcmp(component_name, 'tank') && strcmp(field_name, 'X')
                                         continue;
                                     end
                                     
                                     % --- Skip extrapolation for nozzle.Mode ---
                                     if strcmp(component_name, 'nozzle') && strcmp(field_name, 'Mode')
                                         x.(component_name).(field_name) = original_x.(component_name).(field_name);
                                         % fprintf('Skipping extrapolation for nozzle.Mode, keeping original value: %s\n', x.(component_name).(field_name)); % Optional debug
                                         continue; % Move to the next field
                                     end
                                     % --- End skip for nozzle.Mode ---

                                     if isfield(x.(component_name), field_name) % Check if field exists in x
                                         try 
                                             % Find valid indices where both time and the current field are not NaN
                                             valid_field_time_indices = hist_indices(~isnan(y.time(hist_indices)) & ~isnan(y.(component_name).(field_name)(hist_indices)));
                                             
                                             if length(valid_field_time_indices) >= 2
                                                 time_hist_for_field = y.time(valid_field_time_indices);
                                                 field_hist = y.(component_name).(field_name)(valid_field_time_indices);

                                                 if length(unique(time_hist_for_field)) >= 2 % Need distinct time values
                                                     extrapolated_field_value = interp1(time_hist_for_field, field_hist, extrapolated_time, option, 'extrap');
                                                     x.(component_name).(field_name) = extrapolated_field_value;
                                                     % Optional: fprintf('Extrapolated %s.%s = %.4e\\n', component_name, field_name, extrapolated_field_value);
                                                 else
                                                      fprintf('Warning (Field %s.%s): Not enough distinct time values in history to extrapolate. Keeping original k value.\n', component_name, field_name);
                                                      x.(component_name).(field_name) = original_x.(component_name).(field_name); % Revert to original
                                                 end
                                             else
                                                 fprintf('Warning (Field %s.%s): Not enough valid (time, field) pairs (found %d) to extrapolate. Keeping original k value.\n', component_name, field_name, length(valid_field_time_indices));
                                                 x.(component_name).(field_name) = original_x.(component_name).(field_name); % Revert to original
                                             end
                                         catch ME_field_extrap
                                              fprintf('Warning (Field %s.%s): Extrapolation failed. Error: %s. Keeping original k value.\n', component_name, field_name, ME_field_extrap.message);
                                              x.(component_name).(field_name) = original_x.(component_name).(field_name); % Revert to original
                                         end
                                     end
                                 end % end for fields_j
                             end
                             fields_i = fields_i + 2;
                         end % end while fields_i
                         fprintf('    Step 2 & 3: Updated state x for k=%d with values extrapolated to t=%.4f s (X=1).\n', k, extrapolated_time);
                         x.flags.X_transition_handled = true; % Mark extrapolation as handled
                         x.tank.state = 2; % Explicitly set tank state to vapor after successful extrapolation
                         time_current = extrapolated_time; % Update time_current for the next step calculation

                     else % Time extrapolation failed, use original values
                         fprintf('    Since time extrapolation failed, using originally calculated values for step k and setting X=1.\n');
                         x.tank.X = 1.0;
                         x.flags.X_transition_handled = true; % Mark as handled even if extrapolation failed
                         x.tank.state = 2; % Explicitly set tank state to vapor
                     end
                     % --- End Step 2 & 3 ---

                 else % Not enough history (k < 3)
                     fprintf('    Warning: Tank quality X >= 1 at step k=%d. Not enough history (%d points) for extrapolation. Setting X=1.\n', k, k-1);
                     x.tank.X = 1.0; % Keep the originally calculated x values for step k, but force X to 1
                     x.flags.X_transition_handled = true; % Mark as handled even with insufficient history
                     x.tank.state = 2; % Explicitly set tank state to vapor
                 end
                 % --- End Extrapolation Block ---
                 fprintf('<<< Extrapolation block finished for k=%d.\n\n', k);
                 % Removed break; Allow loop to continue for phase change
            end

        catch ME
            fprintf(2, '\nERROR in LiqFeed at t=%.2f s: %s. Stopping simulation.\n', time_current, ME.message); % Use fprintf(2,...) for errors
             y = fill_remaining_nan(y, k, num_steps, fields_to_log); % Fill from current step k
             k = k - 1; % Adjust k so trimming uses the last *successful* index
             break; % Stop the simulation loop
        end

    elseif x.tank.state == 2 || x.flags.X_transition_handled % Check for Vapor Feed phase (Now Active OR transition handled)
        % --- Vapor Feed Phase ---
        try
            x = VapFeed(x); % Calculate VapFeed state (uses Pc set above if spray mode)
            % Set unused outputs for VapFeed phase if necessary
            x = set_unused_outputs(x, 'VapFeed');

            % --- Explicitly set NHNE components to 0 during VapFeed ---
            if isfield(x, 'inj') % Check if inj struct exists
                if isfield(x.inj, 'mdot_inc')
                    x.inj.mdot_inc = 0;
                end
                if isfield(x.inj, 'mdot_HEM')
                    x.inj.mdot_HEM = 0;
                end
            end
            % --- End setting NHNE components ---

        catch ME
            fprintf(2, '\nERROR in VapFeed at t=%.2f s: %s. Stopping simulation.\n', time_current, ME.message); % Use fprintf(2,...) for errors
             y = fill_remaining_nan(y, k, num_steps, fields_to_log); % Fill from current step k
             k = k - 1; % Adjust k so trimming uses the last *successful* index
             break; % Stop the simulation loop
        end

    else % Tank state is unexpected (-1) or vapor-only when VapFeed is not active
        % --- Post-Run / Error / End Phase ---
        if x.tank.state == 2
             warning('System:VapFeedNotImplementedOrReached', 'Tank is vapor only at t=%.2f s. Stopping flows as VapFeed is not implemented/active.', time_current);
        elseif x.tank.state == -1
             warning('System:TankErrorState', 'Tank state is error (-1) at t=%.2f s. Stopping flows.', time_current);
        else
             % fprintf('Simulation ended or tank state %.0f not handled at t=%.2f s\n', x.tank.state, time_current);
        end
        % Stop calculations, set flow rates to zero, etc.
        x.vent.mdot = 0;
        x.inj.mdot = 0;
        x.fuel.mdot = 0;
        x.comb.mdot = 0;
        x.nozzle.F = 0;
        x = set_unused_outputs(x, 'PostRun');
        % Store this final 'stopped' state before breaking
        y = store_state(y, x, k, fields_to_log);
        break; % Exit loop after handling stop/error state
    end

    % --- Set unused outputs specifically for Spray Test mode ---
    if x.test.mode == 2 % After phase calculation, set unused components to NaN/0
        x = set_unused_outputs(x, 'SprayTest');
    end
    % Note: In Combustion mode (mode 1), Comb and Nozzle are called within LiqFeed/VapFeed,
    % so their outputs are populated there.

    % --- Check for low pressure termination conditions (compared to ambient) ---
    if x.tank.P < x.amb.P
        fprintf('\nSTOP: Simulation stopped at k = %d, t = %.4f s because tank pressure (P=%.2f Pa) dropped below ambient (%.2f Pa).\n', k, time_current, x.tank.P, x.amb.P);
        % Store the state *before* breaking
        y = store_state(y, x, k, fields_to_log);
        break; % Exit the main simulation loop
    elseif x.comb.P < x.amb.P && x.test.mode == 1 % Only check Comb pressure if in combustion mode
        fprintf('\nSTOP: Simulation stopped at k = %d, t = %.4f s because combustion pressure (Pc=%.2f Pa) dropped below ambient (%.2f Pa).\n', k, time_current, x.comb.P, x.amb.P);
        % Store the state *before* breaking
        y = store_state(y, x, k, fields_to_log);
        break; % Exit the main simulation loop
    end

    % --- Store the result for the processed time step (if loop didn't break earlier) --- 
    y = store_state(y, x, k, fields_to_log); 

    % --- Update Time for the *next* iteration --- 
    time_current = time_current + x.time.dt;
    x.time.current = time_current; 

end

% fprintf('Loop finished. Final k value was: %d\\n', k); % Debug print 3 (Removed)

% --- Trim the history structure to the actual number of steps executed ---
last_valid_index = k - 1;
% fprintf('Trimming y structure. last_valid_index = %d\\n', last_valid_index); % Debug print (Removed)

if last_valid_index > 0 % Ensure we executed at least one step
    y.time = y.time(1:last_valid_index);
    i = 1;
    while i <= length(fields_to_log)
        component_name = fields_to_log{i};
        field_names = fields_to_log{i+1};
        if isfield(y, component_name)
            for j = 1:length(field_names)
                 field_name = field_names{j};
                 if isfield(y.(component_name), field_name)
                    % Check if the field itself is not empty before trimming
                    if ~isempty(y.(component_name).(field_name))
                        y.(component_name).(field_name) = y.(component_name).(field_name)(1:last_valid_index);
                    end
                 end
            end
        end
        i = i + 2;
    end
else
    % Handle the case where the loop didn't run even once (e.g., start >= run)
    warning('System:NoStepsExecuted', 'Simulation loop did not execute any steps.');
    % Return an empty structure or specific fields as empty
    y.time = [];
    i = 1;
    while i <= length(fields_to_log)
        component_name = fields_to_log{i};
        field_names = fields_to_log{i+1};
        y.(component_name) = struct(); % Create empty struct for component
        for j = 1:length(field_names)
            y.(component_name).(field_names{j}) = []; % Assign empty array
        end
        i = i + 2;
    end
end

% fprintf('Trimming complete. Final size(y.time) = [%d, %d]\n', size(y.time, 1), size(y.time, 2)); % Debug print 4 (Removed)

% --- Simulation End Message ---
fprintf('Simulation finished.\n');

% --- Replace remaining NaNs with 0 for plotting --- 
% --- 주석 처리 시작 ---
% fprintf('Replacing NaN values with 0 in the final output structure y for plotting...\n');
% i = 1;
% while i <= length(fields_to_log)
%     component_name = fields_to_log{i};
%     field_names = fields_to_log{i+1};
%     if isfield(y, component_name)
%         for j = 1:length(field_names)
%             field_name = field_names{j};
%             if isfield(y.(component_name), field_name) && ~isempty(y.(component_name).(field_name))
%                 current_data = y.(component_name).(field_name);
%                 current_data(isnan(current_data)) = 0;
%                 y.(component_name).(field_name) = current_data;
%             end
%         end
%     end
%     i = i + 2;
% end
% % Also check the time field
% if isfield(y, 'time') && ~isempty(y.time)
%     y.time(isnan(y.time)) = 0; % Should not happen after trimming, but good practice
% end
% fprintf('NaN replacement complete.\n');
% --- 주석 처리 끝 ---

%% Helper Functions (Define below or in separate files)

function y = initialize_history(num_steps, fields_to_log)
    % Initializes the history structure 'y' with NaNs
    y = struct();
    y.time = NaN(1, num_steps); % Initialize time field
    
    % Loop through component-field pairs
    i = 1; 
    while i <= length(fields_to_log)
        component_name = fields_to_log{i};
        field_names = fields_to_log{i+1};
        y.(component_name) = struct(); % Create sub-struct for the component
        for j = 1:length(field_names)
            field_name = field_names{j};
            % Check if the field is 'Mode' under 'nozzle'
            if strcmp(component_name, 'nozzle') && strcmp(field_name, 'Mode')
                y.(component_name).(field_name) = strings(1, num_steps); % Initialize as string array
            else
                y.(component_name).(field_name) = NaN(1, num_steps); % Initialize others as NaN
            end
        end
        i = i + 2;
    end
end

function y = store_state(y, x, k, fields_to_log)
    % Stores the current state from x into y at index k
    y.time(k) = x.time.current; % Store current time first
    
    % Loop through component-field pairs defined outside the function
    i = 1; 
    while i <= length(fields_to_log)
        component_name = fields_to_log{i};
        field_names = fields_to_log{i+1};
        if isfield(x, component_name) % Check if component exists in x
            for j = 1:length(field_names)
                 field_name = field_names{j};
                 if isfield(x.(component_name), field_name) % Check if field exists
                    y.(component_name).(field_name)(k) = x.(component_name).(field_name);
                 % else
                    % Optional: Handle cases where a field might be missing in x 
                    % y.(component_name).(field_name)(k) = NaN; % Or some default 
                 end
            end
        % else 
            % Optional: Handle cases where a component might be missing in x
        end
        i = i + 2;
    end
end

function x = set_unused_outputs(x, phase)
    fields_to_nan = struct();
    switch phase
        case {'PreFeed', 'PostRun'} % Apply same NaNs for PreFeed and PostRun/Stop
            % Injector state might be calculated even in PreFeed if needed later?
            % Assuming only flow rates are zero/NaN in PostRun
            % Remove 'T' from inj list to keep ambient temp during PreFeed
            fields_to_nan.inj = {'mdot', 'P', 'rho', 'state', 'X', 'h', 's', 'kappa', 'mdot_inc', 'mdot_HEM'}; 
            fields_to_nan.fuel = {'Gox', 'rdot', 'mdot'};
            fields_to_nan.comb = {'mdot', 'OF', 'cstar'}; % Removed eta
            fields_to_nan.nozzle = {'Cf', 'F', 'Isp_sl'}; % Keep F here to default to NaN
        case 'LiqFeed' % LiqFeed calculates most things, maybe only vent ratios are NaN if vent disabled?
             if x.vent.mode == 0
                 fields_to_nan.vent = {'ratio_Pcr', 'ratio_P'};
             end
        case 'VapFeed'
             % Similar to LiqFeed, NaN vent ratios if vent is off
             if x.vent.mode == 0
                 fields_to_nan.vent = {'ratio_Pcr', 'ratio_P'};
             end
             % Add other VapFeed specific NaNs if needed
        % --- Add SprayTest Case ---
        case 'SprayTest' % Set fuel, comb (except P), and nozzle outputs to NaN/0
            fields_to_nan.fuel = {'Gox', 'rdot', 'mdot'}; % Keep R and R_out 
            fields_to_nan.comb = {'mdot', 'OF', 'cstar'}; 
            fields_to_nan.nozzle = {'Cf', 'F', 'Isp_sl'}; 
            % Injector and Vent outputs are calculated normally based on ambient backpressure
        % --- End Add SprayTest Case ---
    end

    components = fieldnames(fields_to_nan);
    for i = 1:length(components)
        comp = components{i};
        fields = fields_to_nan.(comp);
        if ~isfield(x, comp)
             x.(comp) = struct();
        end
        for j = 1:length(fields)
            field = fields{j};
            % Set mass flows to 0, others to NaN for SprayTest
            if strcmp(phase, 'SprayTest') && (strcmp(field, 'mdot') || strcmp(field, 'F'))
                 x.(comp).(field) = 0;
            else
                 x.(comp).(field) = NaN;
            end
        end
    end
    
    % --- Explicitly set F=0 only for PreFeed --- 
    if strcmp(phase, 'PreFeed')
        if ~isfield(x, 'nozzle')
            x.nozzle = struct();
        end
        x.nozzle.F = 0;
    end
    % --- End explicit PreFeed F=0 setting ---
end

function y = fill_remaining_nan(y, start_index, end_index, fields_to_log)
    % Fills the history structure with NaNs from start_index to end_index
    if start_index > end_index 
        return; 
    end
    y.time(start_index:end_index) = NaN;
    i = 1; 
    while i <= length(fields_to_log)
        component_name = fields_to_log{i};
        field_names = fields_to_log{i+1};
        for j = 1:length(field_names)
            field_name = field_names{j};
            % Check if the field is 'Mode' under 'nozzle'
            if strcmp(component_name, 'nozzle') && strcmp(field_name, 'Mode')
                y.(component_name).(field_name)(start_index:end_index) = "Not Calculated"; % Fill Mode with specific string
            else
                y.(component_name).(field_name)(start_index:end_index) = NaN; % Fill others with NaN
            end
        end
        i = i + 2;
    end
end

% --- Re-enable GetStateFromHistory --- 
% function x_state = GetStateFromHistory(y, k)
%     x_state = struct();
%     % Check basic validity of y and k
%     if k < 1 || ~isstruct(y) || ~isfield(y, 'time') || k > length(y.time) || isnan(y.time(k))
%         x_state.time.current = NaN;
%         x_state.tank.X = NaN;
%         x_state.tank.m = NaN;
%         x_state.tank.T = NaN;
%         x_state.tank.h = NaN; % Add other essential fields as NaN
%         return;
%     end
%     
%     % Time
%     x_state.time.current = y.time(k);
%     
%     % Tank Properties - Check existence before accessing
%     if isfield(y, 'tank')
%         if isfield(y.tank, 'X') && length(y.tank.X) >= k
%              x_state.tank.X = y.tank.X(k);
%         else; x_state.tank.X = NaN; end
%         
%         if isfield(y.tank, 'm') && length(y.tank.m) >= k % Use lowercase 'm'
%              x_state.tank.m = y.tank.m(k); % Use lowercase 'm'
%         else; x_state.tank.m = NaN; end
% 
%         if isfield(y.tank, 'T') && length(y.tank.T) >= k
%              x_state.tank.T = y.tank.T(k);
%         else; x_state.tank.T = NaN; end
% 
%         if isfield(y.tank, 'h') && length(y.tank.h) >= k
%              x_state.tank.h = y.tank.h(k); % Include enthalpy if needed for alt interpolation
%         else; x_state.tank.h = NaN; end
%     else
%         % Handle case where y.tank doesn't exist (shouldn't happen if init is correct)
%         x_state.tank.X = NaN; x_state.tank.m = NaN; x_state.tank.T = NaN; x_state.tank.h = NaN;
%     end
% 
%     % Add other fields if they are needed by the interpolation logic
%     % or subsequent steps immediately after interpolation
%     
% end

end