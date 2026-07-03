function Plot_Comb_Vc_t(ax, y)
%Plot_Comb_Vc_t Plots chamber gas velocity (Vc) in m/s vs time.
%   Plots y.comb.Vc against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.Vc).

Vc_data = y.comb.Vc; % Data in m/s

plot(ax, y.time, Vc_data, 'c-', 'LineWidth', 1.5); % Cyan solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Velocity (Vc) (m/s)');
title(ax, 'Chamber Gas Velocity vs Time');
legend(ax, 'hide');

end 