function Plot_Inj_Kappa_t(ax, y)
%Plot_Inj_Kappa_t Plots the injector NHNE model parameter kappa vs. time.
%   Plots y.inj.kappa against y.time on the provided axes ax.
%   This value is typically NaN during VapFeed.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.kappa).

plot(ax, y.time, y.inj.kappa, 'Color', [0.3010 0.7450 0.9330], 'LineStyle', '--', 'LineWidth', 1.5); % Light blue dashed line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Kappa (NHNE) (-)');
title(ax, 'Injector NHNE Model Parameter (Kappa) vs Time');

end 