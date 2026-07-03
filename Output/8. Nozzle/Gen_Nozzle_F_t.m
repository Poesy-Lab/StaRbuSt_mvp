%
% Gen_Nozzle_F_t.m
% Generates a .mat file containing nozzle thrust vs. time data.

% Assumes 'y' structure containing simulation results is available.

function Gen_Nozzle_F_t(y, output_filename)
%Gen_Nozzle_F_t Generates a .mat file containing nozzle thrust vs. time data.
%   Saves y.time and y.nozzle.F from the simulation results structure 'y'
%   to the specified .mat file.
%
%   Inputs:
%       y: Simulation results structure (must contain y.time, y.nozzle.F).
%       output_filename: Full path for the output .mat file.

% Define the output filename
% output_filename = 'Nozzle_Thrust_vs_Time.mat';

% Check if the required variables exist in the 'y' structure
if isfield(y, 'time') && ~isempty(y.time) && isfield(y, 'nozzle') && isfield(y.nozzle, 'F') && ~isempty(y.nozzle.F)
    % Extract the data
    time_vector = y.time;
    thrust_vector = y.nozzle.F;

    % Save the data to the specified .mat file
    try
        save(output_filename, 'time_vector', 'thrust_vector');
        % fprintf('Successfully saved nozzle thrust data to %s\n', output_filename);
    catch ME
        warning('Gen_Nozzle_F_t:SaveFailed', 'Error saving nozzle thrust data to %s', output_filename);
        rethrow(ME);
    end
else
    missing_fields = {};
    if ~isfield(y, 'time') || isempty(y.time); missing_fields{end+1} = 'y.time'; end
    if ~isfield(y, 'nozzle') || ~isfield(y.nozzle, 'F') || isempty(y.nozzle.F); missing_fields{end+1} = 'y.nozzle.F'; end
    warning('Gen_Nozzle_F_t:MissingData', ...
            'Could not find required data (%s) in the input structure \'\'y\'\'. File not saved: %s', ...
            strjoin(missing_fields, ', '), output_filename);
end

end
