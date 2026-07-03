function Plot_Tank_Total_H_t(ax, y)
%Plot_Tank_Total_H_t Plots total enthalpy on the provided axes.
%   Plots y.tank.H (in MJ) against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

plot(ax, y.time, y.tank.H / 1e3, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Total (H)'); % kJ
% hold(ax, 'on');
% % Add H_v, H_l plotting here if they become available in y.tank
% hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Total Enthalpy (kJ)');
title(ax, 'Tank Total Enthalpy vs Time');
legend(ax, 'Location', 'best');

end 