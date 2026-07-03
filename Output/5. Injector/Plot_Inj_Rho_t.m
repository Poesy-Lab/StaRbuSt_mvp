function Plot_Inj_Rho_t(ax, y)
%Plot_Inj_Rho_t Plots injector densities (mixture, vapor, liquid) vs. time.
%   Plots y.inj.rho, rho_v, rho_l against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.rho, 
%          y.inj.rho_v, y.inj.rho_l).

plot(ax, y.time, y.inj.rho, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mixture (\rho)'); 
hold(ax, 'on');
plot(ax, y.time, y.inj.rho_v, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Vapor (\rho_v)');
plot(ax, y.time, y.inj.rho_l, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Liquid (\rho_l)');
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Density (kg/m^3)');
title(ax, 'Injector Density (Mixture, Vapor, Liquid) vs Time');
legend(ax, 'show', 'Location', 'best');

end 