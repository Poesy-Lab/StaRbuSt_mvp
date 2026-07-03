function Plot_Tank_T_t(ax, y)
%Plot_Tank_T_t Plots tank temperature over time on the provided axes.
%   Plots y.tank.T against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed
plot(ax, y.time, y.tank.T - 273.15, 'r-', 'LineWidth', 1.5);
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Temperature (°C)');
title(ax, 'Tank Temperature (°C) vs Time');

end 