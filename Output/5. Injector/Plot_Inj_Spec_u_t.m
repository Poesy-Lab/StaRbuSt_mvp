function Plot_Inj_Spec_u_t(ax, y)
%Plot_Inj_Spec_u_t Plots injector spec. internal energy (mix, vap, liq) vs. time.
%   Plots y.inj.u, u_v, u_l (converted to kJ/kg) against y.time on the
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.u, 
%          y.inj.u_v, y.inj.u_l in J/kg).

u_kJ   = y.inj.u / 1000;   % Convert J/kg to kJ/kg
u_v_kJ = y.inj.u_v / 1000; % Convert J/kg to kJ/kg
u_l_kJ = y.inj.u_l / 1000; % Convert J/kg to kJ/kg

plot(ax, y.time, u_kJ,   'b-',  'LineWidth', 1.5, 'DisplayName', 'Mixture (u)'); 
hold(ax, 'on');
plot(ax, y.time, u_v_kJ, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Vapor (u_v)');
plot(ax, y.time, u_l_kJ, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Liquid (u_l)');
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Spec. Internal Energy (kJ/kg)');
title(ax, 'Injector Specific Internal Energy (Mixture, Vapor, Liquid) vs Time');
legend(ax, 'show', 'Location', 'best');

end 