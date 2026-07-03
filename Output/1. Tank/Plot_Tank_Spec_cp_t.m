function Plot_Tank_Spec_cp_t(ax, y)
%Plot_Tank_Spec_cp_t Plots specific heat (cp) values on the provided axes.
%   Plots y.tank.cp, cp_v, cp_l (in kJ/kg-K) against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

plot(ax, y.time, y.tank.cp / 1e3, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mixture (cp)'); % kJ/kg-K
hold(ax, 'on');
plot(ax, y.time, y.tank.cp_v / 1e3, 'r--', 'DisplayName', 'Vapor (cp_v)'); % kJ/kg-K
plot(ax, y.time, y.tank.cp_l / 1e3, 'k--', 'DisplayName', 'Liquid (cp_l)'); % kJ/kg-K, Liquid as dashed
hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Specific Heat cp (kJ/kg-K)');
title(ax, 'Tank Specific Heat (cp) vs Time');
legend(ax, 'Location', 'best');

end 