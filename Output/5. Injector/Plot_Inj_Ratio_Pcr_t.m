function Plot_Inj_Ratio_Pcr_t(ax, y)
%Plot_Inj_Ratio_Pcr_t Plots the injector critical pressure ratio vs. time.
%   Plots y.inj.ratio_Pcr against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.ratio_Pcr).

plot(ax, y.time, y.inj.ratio_Pcr, 'm-.', 'LineWidth', 1.5); % Magenta dash-dot line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Critical Pressure Ratio (-)');
title(ax, 'Injector Critical Pressure Ratio (P_{cr}/P_{inj}) vs Time');

end 