function Plot_Inj_T_t(ax, y)
%Plot_Inj_T_t Plots the injector temperature vs. time.
%   Plots y.inj.T (converted from K to C) against y.time on the 
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.T in K).

T_C = y.inj.T - 273.15; % Convert K to Celsius

plot(ax, y.time, T_C, 'g-', 'LineWidth', 1.5); % Green solid line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Temperature (°C)');
title(ax, 'Injector Temperature vs Time');

end 