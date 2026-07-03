function Plot_Comb_T_t(ax, y)
%Plot_Comb_T_t Plots combustion temperature (T) in Celsius vs time.
%   Plots y.comb.T (converted from K to C) against y.time on the
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.T in K).

T_C = y.comb.T - 273.15; % Convert K to Celsius

plot(ax, y.time, T_C, 'k-', 'LineWidth', 1.5); % Black solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Temperature (T) (°C)');
title(ax, 'Combustion Temperature vs Time');
legend(ax, 'hide');

end 