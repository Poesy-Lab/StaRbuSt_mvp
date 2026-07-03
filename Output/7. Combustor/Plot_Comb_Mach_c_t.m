function Plot_Comb_Mach_c_t(ax, y)
%Plot_Comb_Mach_c_t Plots chamber Mach number (Mach_c) vs time.
%   Plots y.comb.Mach_c against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.Mach_c).

Mach_c_data = y.comb.Mach_c; % Dimensionless

plot(ax, y.time, Mach_c_data, 'm-', 'LineWidth', 1.5); % Magenta solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Mach Number (Mach_c)');
title(ax, 'Chamber Mach Number vs Time');
legend(ax, 'hide');

end 