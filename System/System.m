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
             'H', 'S', 'rho_v', 'rho_l'}, ...
    'vent', {'mdot', 'ratio_Pcr', 'ratio_P'}, ...
    'feed', {'P_out', 'x_out', 'dP_line'}, ...
    'inj',  {'mdot', 'P', 'T', 'rho', 'state', 'X', ...
             'u', 'u_v', 'u_l', ...
             's', 's_v', 's_l', ...
             'h', 'h_v', 'h_l', ...
             'cp', 'cp_v', 'cp_l', ...
             'cv', 'cv_v', 'cv_l', ...
             'rho_v', 'rho_l', ...
             'kappa', 'mdot_inc', 'mdot_HEM', ...
             'alpha2', 'S_slip', 'n_isen', 'choked', 'mdot_SPC', 'ratio_Pcr_HEM', 'x1_in', ...
             'ratio_Pcr', 'ratio_P'}, ...
    'fuel', {'Gox', 'rdot', 'mdot', 'R_out', 'R', 'Ap', 'Ab', 'dR_m'}, ...
    'comb', {'mdot', 'OF', 'cstar', 'P', 'T', 'eta', 'fac_CR', 'Pinj', 'mw', 'gamma', 'rho_c', 'SoS_c', 'R_specific', 'Mach_c', 'Vc', 'f_L1', 'f_L2', 'f_H_pre_chamber', 'f_H_overall', 'f_HL'}, ...
    'nozzle', {'Cf', 'F', 'Isp_sl', 'Mode', 'Pe', 'Pt'} ...
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
                                         if isfield(original_x, component_name) && isfield(original_x.(component_name), field_name)
                                             x.(component_name).(field_name) = original_x.(component_name).(field_name);
                                         else
                                             % In spray test mode, Mode might not be calculated.
                                             % Assign a default string value.
                                             if ~isfield(x, component_name)
                                                 x.(component_name) = struct();
                                             end
                                             x.(component_name).(field_name) = "Not Calculated";
                                         end
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
                                             elseif isempty(valid_field_time_indices)
                                                 % 이력이 전부 NaN = 이번 실행에서 미사용 필드 (예: FML 실행의 kappa) -> 경고 없이 원래 값 유지
                                                 x.(component_name).(field_name) = original_x.(component_name).(field_name);
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

            % --- 액상 전용 모델 진단값이 증기 구간 기록에 남지 않도록 정리 ---
            if isfield(x, 'inj') % Check if inj struct exists
                % NHNE(액상 전용) 성분은 증기 구간에서 항상 비활성
                if isfield(x.inj, 'kappa')
                    x.inj.kappa = NaN;
                end
                if isfield(x.inj, 'x1_in')
                    x.inj.x1_in = NaN; % HEMc 액상 입구 건도 (증기 구간 비활성)
                end
                if isfield(x.inj, 'mdot_inc')
                    x.inj.mdot_inc = 0;
                end
                % FML 증기 모델("NHNE" 키워드)은 mdot_HEM/mdot_SPC/alpha2 등을
                % 매 스텝 직접 계산하므로 유지하고, ICF/CdA 증기 모델일 때만 정리
                if ~contains(x.inj.model_VapFeed, "NHNE", "IgnoreCase", true)
                    if isfield(x.inj, 'mdot_HEM')
                        x.inj.mdot_HEM = 0;
                    end
                    if isfield(x.inj, 'mdot_SPC')
                        x.inj.mdot_SPC = 0;
                    end
                    if isfield(x.inj, 'alpha2')
                        x.inj.alpha2 = NaN;
                    end
                    if isfield(x.inj, 'S_slip')
                        x.inj.S_slip = NaN;
                    end
                    if isfield(x.inj, 'n_isen')
                        x.inj.n_isen = NaN;
                    end
                    if isfield(x.inj, 'choked')
                        x.inj.choked = NaN;
                    end
                    if isfield(x.inj, 'ratio_Pcr_HEM')
                        x.inj.ratio_Pcr_HEM = NaN;
                    end
                end
            end
            % --- End 액상 전용 진단값 정리 ---

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

    % --- Check for low pressure termination conditions (gauge pressure threshold) ---
    pressure_threshold = -0.1 * 1e5; % Pa (equivalent to -0.3 bar gauge pressure)

    if (x.tank.P - x.amb.P) < pressure_threshold
        fprintf('\nSTOP: Simulation stopped at k = %d, t = %.4f s because tank gauge pressure (P_tank - P_amb = %.2f bar) dropped below threshold (%.2f bar).\n', ...
            k, time_current, (x.tank.P - x.amb.P)/1e5, pressure_threshold/1e5);
        % Store the state *before* breaking
        y = store_state(y, x, k, fields_to_log);
        break; % Exit the main simulation loop
    elseif (x.comb.P - x.amb.P) < pressure_threshold && x.test.mode == 1 % Only check Comb pressure if in combustion mode
        fprintf('\nSTOP: Simulation stopped at k = %d, t = %.4f s because combustion gauge pressure (Pc - P_amb = %.2f bar) dropped below threshold (%.2f bar).\n', ...
            k, time_current, (x.comb.P - x.amb.P)/1e5, pressure_threshold/1e5);
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
            fields_to_nan.inj = {'mdot', 'P', 'rho', 'state', 'X', 'h', 's', 'kappa', 'mdot_inc', 'mdot_HEM', ...
                                 'alpha2', 'S_slip', 'n_isen', 'choked', 'mdot_SPC', 'ratio_Pcr_HEM', 'x1_in'}; % NHNE + FML + HEMc 진단값
            fields_to_nan.feed = {'P_out', 'x_out', 'dP_line'}; % 급기 라인 진단값
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
             fields_to_nan.feed = {'P_out', 'x_out', 'dP_line'}; % 급기 라인은 액상 유출 전용 (v1)
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
