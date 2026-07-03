%
% Gen_Nozzle_Mw_t.m
% Generates a .mat file containing nozzle molecular weight vs. time data.

% Assumes 'y' structure containing simulation results is available.

function Gen_Nozzle_Mw_t(y, output_filename)
%Gen_Nozzle_Mw_t Generates a .mat file containing nozzle molecular weight vs. time data.
%   Saves y.time and y.nozzle.mw from the simulation results structure 'y'
%   to the specified .mat file.
%
%   Inputs:
%       y: Simulation results structure (must contain y.time, y.nozzle.mw).
%       output_filename: Full path for the output .mat file.

% Check if the required variables exist in the 'y' structure
if isfield(y, 'time') && ~isempty(y.time) && isfield(y, 'nozzle') && isfield(y.nozzle, 'mw') && ~isempty(y.nozzle.mw)
    % Extract the data
    time_vector = y.time;
    mw_vector = y.nozzle.mw;

    % Save the data to the specified .mat file
    try
        save(output_filename, 'time_vector', 'mw_vector');
        % fprintf('Successfully saved nozzle molecular weight data to %s\n', output_filename);
    catch ME
        warning('Gen_Nozzle_Mw_t:SaveFailed', 'Error saving nozzle molecular weight data to %s', output_filename);
        rethrow(ME);
    end
else
    missing_fields = {};
    if ~isfield(y, 'time') || isempty(y.time); missing_fields{end+1} = 'y.time'; end
    if ~isfield(y, 'nozzle') || ~isfield(y.nozzle, 'mw') || isempty(y.nozzle.mw); missing_fields{end+1} = 'y.nozzle.mw'; end
    warning('Gen_Nozzle_Mw_t:MissingData', ...
            'Could not find required data (%s) in the input structure \'\'y\'\'. File not saved: %s', ...
            strjoin(missing_fields, ', '), output_filename);
end

end 