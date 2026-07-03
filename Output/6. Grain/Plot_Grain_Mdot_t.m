function Plot_Grain_Mdot_t(ax, y)
%Plot_Grain_Mdot_t Plots fuel mass flow rate (mdot) vs time
% and displays total fuel mass consumed.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.mdot).

% Check if the necessary fields exist
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'mdot')
    warning('Plot_Grain_Mdot_t:MissingData', 'Time or y.fuel.mdot data not found in y structure.');
    text(ax, 0.5, 0.5, 'y.fuel.mdot data not available', 'HorizontalAlignment', 'center');
    grid(ax, 'on'); % Still show grid and labels for consistency
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Fuel Mass Flow Rate (kg/s)');
    title(ax, 'Fuel Mass Flow Rate (mdot) vs Time');
    return;
end

% Extract data
time = y.time;
mdot_fuel = y.fuel.mdot;

% Plot mdot_fuel (handle NaNs for plotting)
valid_plot_indices = find(~isnan(mdot_fuel));
if ~isempty(valid_plot_indices)
    plot(ax, time(valid_plot_indices), mdot_fuel(valid_plot_indices), 'g-', 'LineWidth', 1.5); % Changed color to green
else
    plot(ax, NaN, NaN, 'g-'); % Plot NaN if no data for plotting
    warning('Plot_Grain_Mdot_t:NoValidPlotData', 'No valid mdot_fuel data to plot.');
end

title(ax, 'Fuel Mass Flow Rate (mdot) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Fuel Mass Flow Rate (kg/s)');
grid(ax, 'on');
box(ax, 'on');
legend(ax, 'hide'); % Consistent with other plots

% Calculate and Display Total Fuel Mass Consumed
% Use all valid (non-NaN) mdot_fuel data for calculation
valid_calc_indices = find(~isnan(mdot_fuel)); 

if ~isempty(valid_calc_indices) && length(valid_calc_indices) > 1
    time_valid = time(valid_calc_indices);
    mdot_fuel_valid = mdot_fuel(valid_calc_indices);
    
    total_fuel_mass_consumed = trapz(time_valid, mdot_fuel_valid);

    % --- Prepare text for display ---
    display_text = sprintf('Total Fuel Mass = %.3f kg', total_fuel_mass_consumed);

    % --- Display Text on the plot (top-right corner) ---
    text(ax, max(xlim(ax)), max(ylim(ax)), display_text, ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
        'FontSize', 9, 'BackgroundColor', 'white', 'EdgeColor', 'black');

elseif ~isempty(valid_calc_indices) && length(valid_calc_indices) == 1
    warning('Plot_Grain_Mdot_t:SingleDataPointForTrapz', 'Cannot calculate total fuel mass with only one data point.');
else
    warning('Plot_Grain_Mdot_t:NoValidCalcData', 'No valid mdot_fuel data to calculate total fuel mass.');
end

end 