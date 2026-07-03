function Plot_Comb_Cstar_t(ax, y)
%Plot_Comb_Cstar_t Plots theoretical and actual characteristic velocity (cstar) vs time.
%   Plots y.comb.cstar (theoretical, solid line) and 
%   y.comb.cstar .* y.comb.eta (actual, dashed line) against y.time 
%   on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.cstar, y.comb.eta).

% Calculate actual cstar
cstar_actual = NaN(size(y.comb.cstar)); % Pre-allocate with NaN
if isfield(y.comb, 'eta') && ~isempty(y.comb.eta)
    % Only calculate if eta exists and is not empty
    valid_idx = ~isnan(y.comb.cstar) & ~isnan(y.comb.eta);
    cstar_actual(valid_idx) = y.comb.cstar(valid_idx) .* y.comb.eta(valid_idx);
else
    warning('Plot_Comb_Cstar_t:MissingEta', 'y.comb.eta not found or empty. Skipping actual c* calculation.');
end

plot(ax, y.time, y.comb.cstar, 'm-', 'LineWidth', 1.5, 'DisplayName', 'Theoretical c*'); % Magenta solid line
hold(ax, 'on');
plot(ax, y.time, cstar_actual, 'm--', 'LineWidth', 1.5, 'DisplayName', 'Actual c* (with \eta)'); % Magenta dashed line
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Characteristic Velocity (c*) (m/s)');
title(ax, 'Combustor Characteristic Velocity (Theoretical & Actual) vs Time');
legend(ax, 'show', 'Location', 'best'); % Show legend

end 