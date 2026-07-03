function Plot_Nozzle_Rho_c_t(ax, y)
%Plot_Nozzle_Rho_c_t Plots nozzle chamber density vs. time.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.nozzle.rho_c).

% Check if the required variables exist
if isfield(y, 'time') && isfield(y, 'nozzle') && isfield(y.nozzle, 'rho_c')
    t = y.time;
    rho_c = y.nozzle.rho_c;

    % Filter out NaN values
    valid_indices = ~isnan(t) & ~isnan(rho_c);
    t_plot = t(valid_indices);
    rho_c_plot = rho_c(valid_indices);

    if ~isempty(t_plot)
        plot(ax, t_plot, rho_c_plot, 'LineWidth', 1.5);
        xlabel(ax, 'Time (s)');
        ylabel(ax, 'Chamber Density (kg/m^3)');
        title(ax, 'Nozzle Chamber Density vs. Time');
        grid(ax, 'on');
        % legend(ax, 'rho_c', 'Location', 'best'); % Optional legend
    else
        title(ax, 'Nozzle rho_c vs. Time (No valid data to plot)');
        text(ax, 0.5, 0.5, 'No valid data points for rho_c', 'HorizontalAlignment', 'center');
    end
else
    % Handle missing fields
    title(ax, 'Nozzle rho_c vs. Time (Data Missing)');
    text(ax, 0.5, 0.5, sprintf('Missing required fields:\n%s%s', ...
                            iif(~isfield(y, 'time'), 'y.time ', ''), ...
                            iif(~isfield(y, 'nozzle') || ~isfield(y.nozzle, 'rho_c'), 'y.nozzle.rho_c ', '')), ...
         'HorizontalAlignment', 'center');
end

% Helper for conditional string in text (inline if)
function out = iif(condition, true_str, false_str)
    if condition
        out = true_str;
    else
        out = false_str;
    end
end

end 