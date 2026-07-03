function [y, fields_to_log, num_steps] = InitializeSystem(x)
%% Initialize Simulation History and Define Fields to Log
% This function initializes the output structure 'y' and defines the
% fields that will be logged during the simulation.
% Input: x - Initial state structure from Input function.
% Output: y - Pre-allocated structure for time history.
%         fields_to_log - Cell array defining logged variables.
%         num_steps - Total number of simulation steps.

%% Initialization
% Calculate total number of steps
num_steps = round((x.time.stop - x.time.start) / x.time.dt) + 1;

% Define fields to log by calling the dedicated function
fields_to_log = DefineLoggedFields();

% Pre-allocate history structure 'y' for efficiency
y = initialize_history(num_steps, fields_to_log);

end

%% Helper Function

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
            y.(component_name).(field_names{j}) = NaN(1, num_steps);
        end
        i = i + 2;
    end
end 