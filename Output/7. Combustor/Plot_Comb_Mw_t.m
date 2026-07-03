function Plot_Comb_Mw_t(ax, y)
%Plot_Comb_Mw_t Plots combustor molecular weight vs. time.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.mw).

% Check if the required variables exist
if isfield(y, 'time') && isfield(y, 'comb') && isfield(y.comb, 'mw')
    t = y.time;
    mw = y.comb.mw;

    % Filter out NaN values to avoid plotting issues, especially if simulation stopped early
    valid_indices = ~isnan(t) & ~isnan(mw);
    t_plot = t(valid_indices);
    mw_plot = mw(valid_indices);

    if ~isempty(t_plot)
        plot(ax, t_plot, mw_plot, 'LineWidth', 1.5);
        xlabel(ax, 'Time (s)');
        ylabel(ax, 'Molecular Weight (kg/kmol)');
        title(ax, 'Combustor Molecular Weight vs. Time');
        grid(ax, 'on');
        % legend(ax, 'Mw', 'Location', 'best'); % Optional legend
    else
        title(ax, 'Combustor Mw vs. Time (No valid data to plot)');
        text(ax, 0.5, 0.5, 'No valid data points for Mw', 'HorizontalAlignment', 'center');
    end
else
    % Handle missing fields by displaying a message on the plot
    title(ax, 'Combustor Mw vs. Time (Data Missing)');
    text(ax, 0.5, 0.5, sprintf('Missing required fields:\n%s%s', ...
                            iif(~isfield(y, 'time'), 'y.time ', ''), ...
                            iif(~isfield(y, 'comb') || ~isfield(y.comb, 'mw'), 'y.comb.mw ', '')), ...
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
