function Plot_Tank_Spec_s_t(ax, y)
%Plot_Tank_Spec_s_t Plots specific entropies on the provided axes.
%   Plots y.tank.s, s_v, s_l (in kJ/kg-K) against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed
plot(ax, y.time, y.tank.s / 1e3, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mixture (s)'); % kJ/kg-K
hold(ax, 'on');
plot(ax, y.time, y.tank.s_v / 1e3, 'r--', 'DisplayName', 'Vapor (s_v)'); % kJ/kg-K
plot(ax, y.time, y.tank.s_l / 1e3, 'k--', 'DisplayName', 'Liquid (s_l)'); % kJ/kg-K, Liquid as dashed
hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Specific Entropy (kJ/kg-K)');
title(ax, 'Tank Specific Entropies vs Time');
legend(ax, 'Location', 'best');

end 