function [y] = System_new(x)
%% Main System Simulation Function
% This function runs the entire simulation timeline, calling appropriate
% phase functions (PreFeed, LiqFeed, VapFeed) based on time and state.
% Input: x - Initial state structure from Input function.
% Output: y - Structure containing the time history of key variables.

%% Initialization
% Call the initialization function
[y, fields_to_log, num_steps] = InitializeSystem(x);

% Simulation Loop Setup
time_current = x.time.start;
x.time.current = time_current; % Initialize current time in x
k = 1; % Initialize loop counter

%% Simulation Start Message and Progress Tracking
fprintf('Simulation started (Max time: %.2f s)...\n', x.time.stop); % Fixed newline
next_update_time = floor(x.time.start) + 1.0;

%% Simulation Phases (Separate Loops)

if x.test.mode == 1 % --- Combustion Test Mode ---

    % --- PreFeed Phase --- 
    fprintf('Entering PreFeed phase (Combustion Mode)...\n');
    while time_current < (x.time.run - x.time.dt / 10) && k <= num_steps
        % --- Set Ambient Conditions for PreFeed ---
        x.comb.P = x.amb.P; % Ensure Comb pressure is ambient during PreFeed
        fprintf('[DEBUG PreFeed k=%d t=%.4f] x.comb.P set to: %.2f Pa\n', k, time_current, x.comb.P); % Debug Print
        if isfield(x, 'amb') && isfield(x.amb, 'T')
            if isfield(x, 'comb')
                x.comb.T = x.amb.T;
            end
            if isfield(x, 'inj')
                x.inj.T = x.amb.T; % Keep injector temp ambient
                x.inj.P = x.amb.P; % Keep injector pressure ambient
            end
        else
            warning('System:AmbTNotFoundPreFeed', 'Ambient temperature (x.amb.T) not found during PreFeed.');
        end
        
        % --- Progress Update --- 
        if time_current >= next_update_time
            fprintf('Simulation progress: t = %.2f s / %.2f s (PreFeed)\n', next_update_time, x.time.stop);
            next_update_time = next_update_time + 1.0;
        end
    
        % --- Call PreFeed --- 
        try
            x = PreFeed(x);
            % Set unused outputs specific to PreFeed
            x = SetUnusedOutputs(x, 'PreFeed');
    
        catch ME
            warning('System:PreFeedError', 'Error in PreFeed at t=%.4f s: %s. Stopping simulation.', time_current, ME.message);
            y = FillRemainingNaN(y, k, num_steps, fields_to_log); % Fill remaining with NaN
            k = k - 1; % Adjust index for trimming to last valid step
            break; % Exit the PreFeed while loop
        end
    
        % --- Store the result for this step ---
        y = StoreState(y, x, k, fields_to_log);
    
        % --- Update Time and Index for the next iteration --- 
        time_current = time_current + x.time.dt;
        x.time.current = time_current;
        k = k + 1;
    
        % --- Check stop time condition within the loop as well ---
        if time_current >= x.time.stop
            warning('System:StopTimeReachedInPreFeed', 'Stop time reached during PreFeed at t=%.4f s.', time_current);
            break; % Exit PreFeed loop if stop time is reached prematurely
        end
    end
    fprintf('PreFeed phase finished at t = %.4f s (k = %d).\n', time_current, k);
    
    
    % --- Liquid Feed Phase ---
    fprintf('Entering LiqFeed phase (Combustion Mode)...\n');
    while (x.tank.state == 0 || x.tank.state == 1) && k <= num_steps && time_current < x.time.stop
        % --- Progress Update ---
        if time_current >= next_update_time
            fprintf('Simulation progress: t = %.2f s / %.2f s (LiqFeed)\n', next_update_time, x.time.stop);
            next_update_time = next_update_time + 1.0;
        end
    
        % --- Call LiqFeed (Handles Pc iteration internally) ---
        try
            x = LiqFeed(x);
    
            % --- Check if tank is now vapor-only (Transition check) ---
            if isfield(x.tank, 'X') && x.tank.X >= 1
                 fprintf('Tank quality (X=%.4f) reached or exceeded 1 at k = %d, t = %.4f s. Transitioning to VapFeed (if applicable).\n', x.tank.X, k, time_current);
                 % Store state BEFORE breaking the LiqFeed loop
                 y = StoreState(y, x, k, fields_to_log);
                 k = k + 1; % Increment k because this step was calculated
                 break; % Exit LiqFeed loop to potentially enter VapFeed
            end
    
        catch ME
            warning('System:LiqFeedError', 'Error in LiqFeed at t=%.4f s: %s. Stopping simulation.', time_current, ME.message);
            y = FillRemainingNaN(y, k, num_steps, fields_to_log); % Fill remaining with NaN
            k = k - 1; % Adjust index for trimming to last valid step
            break; % Exit the LiqFeed while loop
        end
    
        % --- Check for low pressure termination conditions (Combustion Mode) ---
        if x.tank.P < x.amb.P
            fprintf('Stopping simulation at k = %d, t = %.4f s because tank pressure (P=%.2f Pa) dropped below ambient (%.2f Pa).\n', k, time_current, x.tank.P, x.amb.P);
            % Store the state *before* breaking
            y = StoreState(y, x, k, fields_to_log);
            k = k + 1; % Increment k as this state is stored
            break; % Exit the LiqFeed loop
        elseif x.comb.P < x.amb.P % In Combustion mode, Pc should be above ambient
            fprintf('Stopping simulation at k = %d, t = %.4f s because combustion pressure (Pc=%.2f Pa) dropped below ambient (%.2f Pa).\n', k, time_current, x.comb.P, x.amb.P);
            % Store the state *before* breaking
            y = StoreState(y, x, k, fields_to_log);
            k = k + 1; % Increment k as this state is stored
            break; % Exit the LiqFeed loop
        end
    
        % --- Store the result for this step ---
        y = StoreState(y, x, k, fields_to_log);
    
        % --- Update Time and Index for the next iteration --- 
        time_current = time_current + x.time.dt;
        x.time.current = time_current;
        k = k + 1;
    
    end
    fprintf('LiqFeed phase finished at t = %.4f s (k = %d).\n', time_current, k);
    
    
    % --- Vapor Feed Phase (Placeholder) ---
    % fprintf('Entering VapFeed phase (Combustion Mode)...\n');
    % while x.tank.state == 2 && k <= num_steps && time_current < x.time.stop
    %     % ... VapFeed logic for Combustion Mode ...
    % end
    % fprintf('VapFeed phase finished at t = %.4f s (k = %d).\n', time_current, k);

elseif x.test.mode == 2 % --- Spray Test Mode ---

    fprintf('Entering Spray Test Mode loop...\n');
    while time_current < x.time.stop && k <= num_steps
        % --- Progress Update --- 
        if time_current >= next_update_time
            fprintf('Simulation progress: t = %.2f s / %.2f s (Spray Test)\n', next_update_time, x.time.stop);
            next_update_time = next_update_time + 1.0;
        end

        % --- Set Combustor Pressure to Ambient ---
        x.comb.P = x.amb.P; 
        x.comb.T = x.amb.T; % Also keep comb T ambient
        if isfield(x, 'inj') % Keep injector temp ambient too
            x.inj.T = x.amb.T; 
        end

        % --- Calculate Vent Flow ---
        try
            if x.vent.mode == 1
                if contains(x.vent.model, "ICF", "IgnoreCase", true)
                    x = Vent_ICF(x);
                elseif contains(x.vent.model, "CdA", "IgnoreCase", true)
                    x = Vent_CdA(x);
                else
                    warning('System:UnknownVentModelSpray', 'Unknown vent model: %s. No vent flow.', x.vent.model);
                    x.vent.mdot = 0;
                end
            else
                x.vent.mdot = 0;
            end
        catch ME_vent
             warning('System:VentErrorSpray', 'Error in Vent calculation (Spray Mode) at t=%.4f s: %s.', time_current, ME_vent.message);
             x.vent.mdot = 0; % Assume zero flow on error
        end

        % --- Calculate Injector Flow (Liquid models, ambient backpressure) ---
        try 
            % Calculate injector exit state based on ambient backpressure
            x = InjState_LiqFeed(x); % Uses x.comb.P which is set to ambient
            
            % Calculate injector mass flow rate
            if contains(x.inj.model_LiqFeed, "CdA", "IgnoreCase", true) 
                 x = Inj_CdA_LiqFeed(x);
            elseif contains(x.inj.model_LiqFeed, "NHNE", "IgnoreCase", true) 
                 x = Inj_NHNE_LiqFeed(x); 
            else
                error('System:UnknownInjectorModelSpray', 'Unknown liquid injector model: %s', x.inj.model_LiqFeed);
            end
        catch ME_inj
            warning('System:InjectorErrorSpray', 'Error in Injector calculation (Spray Mode) at t=%.4f s: %s.', time_current, ME_inj.message);
            x.inj.mdot = 0; % Assume zero flow on error
        end

        % --- Update Tank State (using LiqFeed update, as injector flows) ---
        try
            x = Tank_LiqFeed(x); % Uses x.vent.mdot and x.inj.mdot
        catch ME_tank
            warning('System:TankUpdateErrorSpray', 'Error in Tank Update (Spray Mode) at t=%.4f s: %s. Stopping.', time_current, ME_tank.message);
            y = FillRemainingNaN(y, k, num_steps, fields_to_log); 
            k = k - 1; 
            break; % Exit spray test loop
        end

        % --- Set unused outputs for Spray Test ---
        x = SetUnusedOutputs(x, 'SprayTest');

        % --- Check for low tank pressure termination ---
        if x.tank.P < x.amb.P
            fprintf('Stopping simulation (Spray Mode) at k = %d, t = %.4f s because tank pressure (P=%.2f Pa) dropped below ambient (%.2f Pa).\n', k, time_current, x.tank.P, x.amb.P);
            y = StoreState(y, x, k, fields_to_log); % Store final state
            k = k + 1; 
            break; % Exit spray test loop
        end

        % --- Store the result for this step ---
        y = StoreState(y, x, k, fields_to_log);

        % --- Update Time and Index for the next iteration --- 
        time_current = time_current + x.time.dt;
        x.time.current = time_current;
        k = k + 1;
    end
    fprintf('Spray Test Mode loop finished at t = %.4f s (k = %d).\n', time_current, k);

end % End of test mode selection (if/elseif)


% --- Post-Run / Final State Handling ---
% Check if loop terminated early or normally
if k > num_steps && time_current < x.time.stop
    warning('System:MaxStepsReached', 'Maximum number of steps (%d) reached before stop time.', num_steps);
    last_valid_index = num_steps;
elseif k == 1 % Handle case where no loops ran at all
    last_valid_index = 0;
    warning('System:NoStepsExecuted', 'Simulation did not execute any steps.');
else
    % Loop finished normally or broke early, k points to the *next* index or the index *after* break
    last_valid_index = k - 1; 
end

% --- Trim History Structure ---
fprintf('Trimming results to %d steps...\n', last_valid_index);
if last_valid_index > 0 
    y.time = y.time(1:last_valid_index);
    i = 1;
    while i <= length(fields_to_log)
        component_name = fields_to_log{i};
        field_names = fields_to_log{i+1};
        if isfield(y, component_name)
            for j = 1:length(field_names)
                 field_name = field_names{j};
                 if isfield(y.(component_name), field_name)
                    if ~isempty(y.(component_name).(field_name))
                        current_length = length(y.(component_name).(field_name));
                        if current_length >= last_valid_index
                            y.(component_name).(field_name) = y.(component_name).(field_name)(1:last_valid_index);
                        else
                           warning('System:TrimSizeMismatch', 'Field %s.%s has fewer elements (%d) than expected (%d). Trimming to available length.', ...
                                   component_name, field_name, current_length, last_valid_index);
                           y.(component_name).(field_name) = y.(component_name).(field_name)(1:end);
                        end
                    end
                 end
            end
        end
        i = i + 2;
    end
else
    % If no steps executed, clear all fields
    y.time = [];
    i = 1;
    while i <= length(fields_to_log)
        component_name = fields_to_log{i};
        field_names = fields_to_log{i+1};
        y.(component_name) = struct();
        for j = 1:length(field_names)
            y.(component_name).(field_names{j}) = [];
        end
        i = i + 2;
    end
end

% --- Simulation End Message ---
fprintf('Simulation finished.\n');

%% Helper Functions
% (Moved to separate .m files: StoreState.m, SetUnusedOutputs.m, FillRemainingNaN.m)

end % End of System function
