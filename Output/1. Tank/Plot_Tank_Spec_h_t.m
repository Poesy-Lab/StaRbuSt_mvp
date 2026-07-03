function Plot_Tank_Spec_h_t(ax, y)
%Plot_Tank_Spec_h_t Plots specific enthalpies on the provided axes.
%   Plots y.tank.h, h_v, h_l (in kJ/kg) against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed
plot(ax, y.time, y.tank.h / 1e3, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mixture (h)'); % kJ/kg
hold(ax, 'on');
plot(ax, y.time, y.tank.h_v / 1e3, 'r--', 'DisplayName', 'Vapor (h_v)'); % kJ/kg
plot(ax, y.time, y.tank.h_l / 1e3, 'k--', 'DisplayName', 'Liquid (h_l)'); % kJ/kg, Liquid as dashed
hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Specific Enthalpy (kJ/kg)');
title(ax, 'Tank Specific Enthalpies vs Time');
legend(ax, 'Location', 'best');

end 