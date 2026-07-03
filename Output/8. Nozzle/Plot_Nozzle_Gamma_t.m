function Plot_Nozzle_Gamma_t(ax, y)
%Plot_Nozzle_Gamma_t Plots nozzle specific heat ratio vs. time.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.nozzle.gamma).

% Check if the required variables exist
if isfield(y, 'time') && isfield(y, 'nozzle') && isfield(y.nozzle, 'gamma')
    t = y.time;
    gamma = y.nozzle.gamma;

    % Filter out NaN values
    valid_indices = ~isnan(t) & ~isnan(gamma);
    t_plot = t(valid_indices);
    gamma_plot = gamma(valid_indices);

    if ~isempty(t_plot)
        plot(ax, t_plot, gamma_plot, 'LineWidth', 1.5);
        xlabel(ax, 'Time (s)');
        ylabel(ax, 'Specific Heat Ratio (-)');
        title(ax, 'Nozzle Chamber Specific Heat Ratio (Gamma) vs. Time');
        grid(ax, 'on');
        % legend(ax, 'Gamma', 'Location', 'best'); % Optional legend
    else
        title(ax, 'Nozzle Gamma vs. Time (No valid data to plot)');
        text(ax, 0.5, 0.5, 'No valid data points for Gamma', 'HorizontalAlignment', 'center');
    end
else
    % Handle missing fields
    title(ax, 'Nozzle Gamma vs. Time (Data Missing)');
    text(ax, 0.5, 0.5, sprintf('Missing required fields:\n%s%s', ...
                            iif(~isfield(y, 'time'), 'y.time ', ''), ...
                            iif(~isfield(y, 'nozzle') || ~isfield(y.nozzle, 'gamma'), 'y.nozzle.gamma ', '')), ...
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