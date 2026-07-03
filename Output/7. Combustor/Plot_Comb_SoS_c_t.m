function Plot_Comb_SoS_c_t(ax, y)
%Plot_Comb_SoS_c_t Plots chamber speed of sound (SoS_c) in m/s vs time.
%   Plots y.comb.SoS_c against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.SoS_c).

SoS_c_data = y.comb.SoS_c; % Data in m/s

plot(ax, y.time, SoS_c_data, 'b-', 'LineWidth', 1.5); % Blue solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'SoS_c (m/s)');
title(ax, 'Chamber Speed of Sound vs Time');
legend(ax, 'hide');

end 