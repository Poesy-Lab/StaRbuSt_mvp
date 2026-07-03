function Plot_Inj_State_t(ax, y)
%Plot_Inj_State_t Plots the injector fluid state vs. time.
%   Plots y.inj.state against y.time on the provided axes ax.
%   Uses stairs plot for discrete state values.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.state).

stairs(ax, y.time, y.inj.state, 'm-', 'LineWidth', 1.5); % Magenta stairs plot
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector State (-)');
title(ax, 'Injector Fluid State vs Time');
yticks(ax, [-1, 0, 1, 2]);
yticklabels(ax, {'Error', 'Liquid', 'Saturated', 'Gas'});
ylim(ax, [-1.5, 2.5]);

end 