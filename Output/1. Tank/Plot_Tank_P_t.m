function Plot_Tank_P_t(ax, y)
%Plot_Tank_P_t Plots tank pressure over time on the provided axes.
%   Plots y.tank.P (converted to MPa) against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed: Figure creation handled by caller
plot(ax, y.time, y.tank.P / 1e5, 'b-', 'LineWidth', 1.5); % Convert Pa to bar
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Pressure (bar)');
title(ax, 'Tank Pressure vs Time');
% legend(...) % Not applicable for single line plot
% hold off; % Not needed as hold state is managed by caller if necessary

end 