%
% Gen_Nozzle_Gamma_t.m
% Generates a .mat file containing nozzle specific heat ratio vs. time data.

% Assumes 'y' structure containing simulation results is available.

function Gen_Nozzle_Gamma_t(y, output_filename)
%Gen_Nozzle_Gamma_t Generates a .mat file containing nozzle specific heat ratio vs. time data.
%   Saves y.time and y.nozzle.gamma from the simulation results structure 'y'
%   to the specified .mat file.
%
%   Inputs:
%       y: Simulation results structure (must contain y.time, y.nozzle.gamma).
%       output_filename: Full path for the output .mat file.

% Check if the required variables exist in the 'y' structure
if isfield(y, 'time') && ~isempty(y.time) && isfield(y, 'nozzle') && isfield(y.nozzle, 'gamma') && ~isempty(y.nozzle.gamma)
    % Extract the data
    time_vector = y.time;
    gamma_vector = y.nozzle.gamma;

    % Save the data to the specified .mat file
    try
        save(output_filename, 'time_vector', 'gamma_vector');
        % fprintf('Successfully saved nozzle specific heat ratio data to %s\n', output_filename);
    catch ME
        warning('Gen_Nozzle_Gamma_t:SaveFailed', 'Error saving nozzle specific heat ratio data to %s', output_filename);
        rethrow(ME);
    end
else
    missing_fields = {};
    if ~isfield(y, 'time') || isempty(y.time); missing_fields{end+1} = 'y.time'; end
    if ~isfield(y, 'nozzle') || ~isfield(y.nozzle, 'gamma') || isempty(y.nozzle.gamma); missing_fields{end+1} = 'y.nozzle.gamma'; end
    warning('Gen_Nozzle_Gamma_t:MissingData', ...
            'Could not find required data (%s) in the input structure \'\'y\'\'. File not saved: %s', ...
            strjoin(missing_fields, ', '), output_filename);
end

end 