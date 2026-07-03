function Plot_Inj_P_t(ax, y)
%Plot_Inj_P_t Plots the injector pressure vs. time.
%   Plots y.inj.P (converted from Pa to bar) against y.time on the 
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.P in Pa).

P_bar = y.inj.P / 1e5; % Convert Pa to bar

plot(ax, y.time, P_bar, 'r-', 'LineWidth', 1.5); % Red solid line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Pressure (bar)');
title(ax, 'Injector Pressure vs Time');

end 