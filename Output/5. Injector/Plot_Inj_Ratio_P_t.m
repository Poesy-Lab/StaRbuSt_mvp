function Plot_Inj_Ratio_P_t(ax, y)
%Plot_Inj_Ratio_P_t Plots the injector pressure ratio vs. time.
%   Plots y.inj.ratio_P (downstream/injector pressure) against y.time 
%   on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.ratio_P).

plot(ax, y.time, y.inj.ratio_P, 'c-.', 'LineWidth', 1.5); % Cyan dash-dot line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Pressure Ratio (-)');
title(ax, 'Injector Pressure Ratio (P_{down}/P_{inj}) vs Time');

end 