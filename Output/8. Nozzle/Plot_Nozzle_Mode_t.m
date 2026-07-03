function Plot_Nozzle_Mode_t(ax, y)
%Plot_Nozzle_Mode_t Plots nozzle operating mode changes vs time using numerical mapping.
%   Maps mode strings to predefined numbers and plots using stairs.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.nozzle.Mode).

% Extract data
time = y.time;
Mode_raw = y.nozzle.Mode;

% Ensure data is not empty
if isempty(time) || isempty(Mode_raw)
    warning('Plot_Nozzle_Mode_t:EmptyData', 'Time or Mode data is empty. Skipping plot.');
    title(ax, 'Nozzle Mode vs Time (No Data)');
    return;
end

% --- Map Mode Strings to Numbers ---
mode_numbers = zeros(size(Mode_raw)); % Initialize with 0 (Other/Error)

% Handle different input types for Mode_raw
if isstring(Mode_raw)
    modes_to_process = Mode_raw;
elseif iscell(Mode_raw)
    modes_to_process = string(Mode_raw); % Convert cell to string array
else
    warning('Plot_Nozzle_Mode_t:UnsupportedModeType', 'Mode data is not string or cell array. Attempting conversion.');
    try
        modes_to_process = string(Mode_raw); % Try converting
    catch
         warning('Plot_Nozzle_Mode_t:ConversionFailed', 'Failed to convert Mode data to string array. Skipping plot.');
         title(ax, 'Nozzle Mode vs Time (Data Type Error)');
         return;
    end
end

for i = 1:length(modes_to_process)
    current_mode = modes_to_process(i);
    if ismissing(current_mode) || current_mode == "" || current_mode == "Not Calculated"
         mode_numbers(i) = 0; % Explicitly map empty/missing/Not Calculated to 0 initially
    end
    
    switch current_mode
        case "Invalid Inputs"
            mode_numbers(i) = 1;
        case "OverExpanded"
            mode_numbers(i) = 2;
        case "Pexit"
            mode_numbers(i) = 3;
        case "UnderExpanded"
            mode_numbers(i) = 4;
        case "Separated"
            mode_numbers(i) = 5;
        % All other non-empty strings map to 0 (Other/Error) by default init
        % case "CEA Error - Invalid Cf" 
        % case "CEA Error - Call Failed"
        % case "Extract Failed"
        % case "Unknown"
        %     mode_numbers(i) = 0;
    end
end
% --- End Mapping ---

% Plot mode numbers as a step plot
stairs(ax, time, mode_numbers, 'b-', 'LineWidth', 1.5);

% Configure Y-axis 
yticks(ax, 0:5);
yticklabels(ax, {'Other/Error', 'Invalid Inputs', 'OverExpanded', 'Pexit', 'UnderExpanded', 'Separated'});
ylim(ax, [-0.5 5.5]); % Adjust limits

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Nozzle Mode');
title(ax, 'Nozzle Mode vs Time');
legend(ax, 'hide');

% Enable default data cursor (will show time and numerical mode value)
datacursormode(ancestor(ax, 'figure'));

% --- Remove Custom Data Tip Function ---
% function txt = modeDataTipUpdateFcn(~, event_obj, time_all, Mode_all)
% ... (function code removed) ...
% end

end 