function Plot_Inj_X_t(ax, y)
%Plot_Inj_X_t Plots the injector fluid quality (vapor mass fraction) vs. time.
%   Plots y.inj.X against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.X).

plot(ax, y.time, y.inj.X, 'c-', 'LineWidth', 1.5); % Cyan solid line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Quality (-)');
title(ax, 'Injector Fluid Quality vs Time');
ylim(ax, [-0.1, 1.1]); % Set y-axis limits slightly outside 0-1

end 