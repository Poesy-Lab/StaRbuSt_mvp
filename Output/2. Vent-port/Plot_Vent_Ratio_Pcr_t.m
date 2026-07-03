function Plot_Vent_Ratio_Pcr_t(ax, y)
%Plot_Vent_Ratio_Pcr_t Plots the critical pressure ratio for vent flow.
%   Plots y.vent.ratio_Pcr against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.vent.ratio_Pcr).

plot(ax, y.time, y.vent.ratio_Pcr, 'm-', 'LineWidth', 1.5); % Magenta solid line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Critical Pressure Ratio (-)');
title(ax, 'Vent Critical Pressure Ratio vs Time');

end 