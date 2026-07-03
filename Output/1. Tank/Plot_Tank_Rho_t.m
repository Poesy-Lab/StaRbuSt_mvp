function Plot_Tank_Rho_t(ax, y)
%Plot_Tank_Rho_t Plots tank densities over time on the provided axes.
%   Plots y.tank.rho, rho_v, rho_l against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed
plot(ax, y.time, y.tank.rho, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mixture (rho)');
hold(ax, 'on');
plot(ax, y.time, y.tank.rho_v, 'r--', 'DisplayName', 'Vapor (rho_v)');
plot(ax, y.time, y.tank.rho_l, 'k--', 'DisplayName', 'Liquid (rho_l)'); % Liquid as dashed line
hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Density (kg/m^3)');
title(ax, 'Tank Densities vs Time');
legend(ax, 'Location', 'best');

end 