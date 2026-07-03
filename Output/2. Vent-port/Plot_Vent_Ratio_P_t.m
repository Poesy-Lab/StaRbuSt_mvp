function Plot_Vent_Ratio_P_t(ax, y)
%Plot_Vent_Ratio_P_t Plots the actual pressure ratio for vent flow.
%   Plots y.vent.ratio_P against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.vent.ratio_P).

plot(ax, y.time, y.vent.ratio_P, 'c-', 'LineWidth', 1.5); % Cyan solid line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Pressure Ratio (Pamb/Ptank) (-)');
title(ax, 'Vent Pressure Ratio vs Time');

end 