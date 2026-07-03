function Plot_Tank_Total_S_t(ax, y)
%Plot_Tank_Total_S_t Plots total entropy on the provided axes.
%   Plots y.tank.S (in kJ/K) against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

plot(ax, y.time, y.tank.S / 1e3, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Total (S)'); % kJ/K
% hold(ax, 'on'); % Hold is off by default, only needed if plotting more lines
% % Add S_v, S_l plotting here if they become available in y.tank
% hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Total Entropy (kJ/K)');
title(ax, 'Tank Total Entropy vs Time');
legend(ax, 'Location', 'best');

end 