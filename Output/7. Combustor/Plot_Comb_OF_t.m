function Plot_Comb_OF_t(ax, y)
%Plot_Comb_OF_t Plots O/F ratio in combustor vs time.
%   Plots y.comb.OF against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.OF).

plot(ax, y.time, y.comb.OF, 'm-', 'LineWidth', 1.5); % Magenta solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'O/F Ratio');
title(ax, 'Combustor O/F Ratio vs Time');
legend(ax, 'hide');

end 