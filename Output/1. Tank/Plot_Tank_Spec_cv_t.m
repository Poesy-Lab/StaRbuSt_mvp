function Plot_Tank_Spec_cv_t(ax, y)
%Plot_Tank_Spec_cv_t Plots specific heat (cv) values on the provided axes.
%   Plots y.tank.cv, cv_v, cv_l (in kJ/kg-K) against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

plot(ax, y.time, y.tank.cv / 1e3, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mixture (cv)'); % kJ/kg-K
hold(ax, 'on');
plot(ax, y.time, y.tank.cv_v / 1e3, 'r--', 'DisplayName', 'Vapor (cv_v)'); % kJ/kg-K
plot(ax, y.time, y.tank.cv_l / 1e3, 'k--', 'DisplayName', 'Liquid (cv_l)'); % kJ/kg-K, Liquid as dashed
hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Specific Heat cv (kJ/kg-K)');
title(ax, 'Tank Specific Heat (cv) vs Time');
legend(ax, 'Location', 'best');

end 