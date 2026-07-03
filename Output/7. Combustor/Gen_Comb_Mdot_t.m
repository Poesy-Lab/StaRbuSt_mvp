% Output/7. Combustor/Gen_Comb_Mdot_t.m
% Generates a .mat file containing combustor mass flow rate vs. time data.

function Gen_Comb_Mdot_t(y, output_filename)
%Gen_Comb_Mdot_t Generates a .mat file containing combustor mass flow rate vs. time data.
%   Saves y.time and y.comb.mdot from the simulation results structure 'y'
%   to the specified .mat file.
%
%   Inputs:
%       y: Simulation results structure (must contain y.time, y.comb.mdot).
%       output_filename: Full path for the output .mat file.

% Check if the required variables exist in the 'y' structure
if isfield(y, 'time') && ~isempty(y.time) && isfield(y, 'comb') && isfield(y.comb, 'mdot') && ~isempty(y.comb.mdot)
    % Extract the data
    time_vector = y.time;
    mdot_vector = y.comb.mdot;

    % Save the data to the specified .mat file
    try
        save(output_filename, 'time_vector', 'mdot_vector');
        % fprintf('Successfully saved combustor mdot data to %s\n', output_filename);
    catch ME
        warning('Gen_Comb_Mdot_t:SaveFailed', 'Error saving combustor mdot data to %s', output_filename);
        rethrow(ME);
    end
else
    missing_fields = {};
    if ~isfield(y, 'time') || isempty(y.time); missing_fields{end+1} = 'y.time'; end
    if ~isfield(y, 'comb') || ~isfield(y.comb, 'mdot') || isempty(y.comb.mdot); missing_fields{end+1} = 'y.comb.mdot'; end
    warning('Gen_Comb_Mdot_t:MissingData', ...
            'Could not find required data (%s) in the input structure \'\'y\'\'. File not saved: %s', ...
            strjoin(missing_fields, ', '), output_filename);
end

end 