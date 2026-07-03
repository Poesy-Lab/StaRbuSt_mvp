function Plot_Tank_X_t(ax, y)
%Plot_Tank_X_t Plots tank quality over time on the provided axes.
%   Plots y.tank.X against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed
plot(ax, y.time, y.tank.X, 'g-', 'LineWidth', 1.5);
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Quality (X)');
title(ax, 'Tank Quality vs Time');
ylim(ax, [0, 1.1]); % Ensure Y-axis includes 0 and 1 comfortably

end 