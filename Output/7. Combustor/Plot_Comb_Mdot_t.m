function Plot_Comb_Mdot_t(ax, y)
%Plot_Comb_Mdot_t Plots total mass flow rate through combustor vs time
% and displays total propellant mass.
%   Plots y.comb.mdot against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.mdot).

% Extract data
time = y.time;
mdot = y.comb.mdot;

% Plot mdot (handle NaNs for plotting)
valid_plot_indices = find(~isnan(mdot));
if ~isempty(valid_plot_indices)
    plot(ax, time(valid_plot_indices), mdot(valid_plot_indices), 'b-', 'LineWidth', 1.5); 
else
    plot(ax, NaN, NaN, 'b-'); % Plot NaN if no data for plotting
    warning('Plot_Comb_Mdot_t:NoValidPlotData', 'No valid mdot data to plot.');
end

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Mass Flow Rate (mdot) (kg/s)');
title(ax, 'Combustor Mass Flow Rate vs Time');
legend(ax, 'hide');

% Calculate and Display Total Propellant Mass
% Use all valid (non-NaN) mdot data for calculation
valid_calc_indices = find(~isnan(mdot)); 

if ~isempty(valid_calc_indices) && length(valid_calc_indices) > 1
    % Ensure time_valid corresponds to mdot_valid by using the same indices
    time_valid = time(valid_calc_indices);
    mdot_valid = mdot(valid_calc_indices);
    
    total_propellant_mass = trapz(time_valid, mdot_valid);

    % --- Prepare text for display ---
    display_text = sprintf('Total Propellant Mass = %.3f kg', total_propellant_mass);

    % --- Display Text on the plot (top-right corner) ---
    % Ensure plot limits are somewhat established before placing text.
    % The plot command above should do this.
    text(ax, max(xlim(ax)), max(ylim(ax)), display_text, ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
        'FontSize', 9, 'BackgroundColor', 'white', 'EdgeColor', 'black');

elseif ~isempty(valid_calc_indices) && length(valid_calc_indices) == 1
    warning('Plot_Comb_Mdot_t:SingleDataPointForTrapz', 'Cannot calculate total propellant mass with only one data point.');
else
    warning('Plot_Comb_Mdot_t:NoValidCalcData', 'No valid mdot data to calculate total propellant mass.');
end

end 