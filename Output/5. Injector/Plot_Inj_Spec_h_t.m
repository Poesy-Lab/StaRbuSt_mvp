function Plot_Inj_Spec_h_t(ax, y)
%Plot_Inj_Spec_h_t Plots injector spec. enthalpy (mix, vap, liq) vs. time.
%   Plots y.inj.h, h_v, h_l (converted to kJ/kg) against y.time on the
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.h, 
%          y.inj.h_v, y.inj.h_l in J/kg).

h_kJ   = y.inj.h / 1000;   % Convert J/kg to kJ/kg
h_v_kJ = y.inj.h_v / 1000; % Convert J/kg to kJ/kg
h_l_kJ = y.inj.h_l / 1000; % Convert J/kg to kJ/kg

plot(ax, y.time, h_kJ,   'b-',  'LineWidth', 1.5, 'DisplayName', 'Mixture (h)'); 
hold(ax, 'on');
plot(ax, y.time, h_v_kJ, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Vapor (h_v)');
plot(ax, y.time, h_l_kJ, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Liquid (h_l)');
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Spec. Enthalpy (kJ/kg)');
title(ax, 'Injector Specific Enthalpy (Mixture, Vapor, Liquid) vs Time');
legend(ax, 'show', 'Location', 'best');

end 