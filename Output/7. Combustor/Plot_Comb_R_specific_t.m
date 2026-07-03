function Plot_Comb_R_specific_t(ax, y)
%Plot_Comb_R_specific_t Plots chamber specific gas constant (R_specific) in J/(kg*K) vs time.
%   Plots y.comb.R_specific against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.R_specific).

R_specific_data = y.comb.R_specific; % Data in J/(kg*K)

plot(ax, y.time, R_specific_data, 'g-', 'LineWidth', 1.5); % Green solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'R_{specific} (J/kg*K)');
title(ax, 'Chamber Specific Gas Constant vs Time');
legend(ax, 'hide');

end 