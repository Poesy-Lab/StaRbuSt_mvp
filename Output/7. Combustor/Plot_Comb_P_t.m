function Plot_Comb_P_t(ax, y)
%Plot_Comb_P_t Plots combustion pressure (P) in bar vs time.
%   Plots y.comb.P (converted from Pa to bar) against y.time on the
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.P in Pa).

P_bar = y.comb.P / 1e5; % Convert Pa to bar

plot(ax, y.time, P_bar, 'r-', 'LineWidth', 1.5); % Red solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Pressure (P) (bar)');
title(ax, 'Combustion Pressure vs Time');
legend(ax, 'hide');

end 