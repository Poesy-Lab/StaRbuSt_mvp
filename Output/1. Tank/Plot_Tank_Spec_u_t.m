function Plot_Tank_Spec_u_t(ax, y)
%Plot_Tank_Spec_u_t Plots specific internal energies on the provided axes.
%   Plots y.tank.u, u_v, u_l (in kJ/kg) against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed
plot(ax, y.time, y.tank.u / 1e3, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mixture (u)'); % kJ/kg
hold(ax, 'on');
plot(ax, y.time, y.tank.u_v / 1e3, 'r--', 'DisplayName', 'Vapor (u_v)'); % kJ/kg
plot(ax, y.time, y.tank.u_l / 1e3, 'k--', 'DisplayName', 'Liquid (u_l)'); % kJ/kg, Liquid as dashed
hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Specific Internal Energy (kJ/kg)');
title(ax, 'Tank Specific Internal Energies vs Time');
legend(ax, 'Location', 'best');

end 