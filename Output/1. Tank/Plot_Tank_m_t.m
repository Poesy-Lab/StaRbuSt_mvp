function Plot_Tank_m_t(ax, y)
%Plot_Tank_m_t Plots tank masses over time on the provided axes.
%   Plots y.tank.m, m_v, m_l against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed
plot(ax, y.time, y.tank.m, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Total (m)');
hold(ax, 'on');
plot(ax, y.time, y.tank.m_v, 'r--', 'DisplayName', 'Vapor (m_v)');
plot(ax, y.time, y.tank.m_l, 'k--', 'DisplayName', 'Liquid (m_l)'); % Liquid as dashed line
hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Mass (kg)');
title(ax, 'Tank Mass Components vs Time');
legend(ax, 'Location', 'best');

end 