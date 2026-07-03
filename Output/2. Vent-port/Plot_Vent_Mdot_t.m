function Plot_Vent_Mdot_t(ax, y)
%Plot_Vent_Mdot_t Plots the mass flow rate through the vent port.
%   Plots y.vent.mdot (in kg/s) against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.vent.mdot).

plot(ax, y.time, y.vent.mdot, 'k-', 'LineWidth', 1.5); % Black solid line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Vent Mass Flow Rate (kg/s)');
title(ax, 'Vent Mass Flow Rate vs Time');

end 