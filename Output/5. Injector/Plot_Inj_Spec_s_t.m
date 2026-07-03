function Plot_Inj_Spec_s_t(ax, y)
%Plot_Inj_Spec_s_t Plots injector spec. entropy (mix, vap, liq) vs. time.
%   Plots y.inj.s, s_v, s_l (converted to kJ/kg-K) against y.time on the
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.s, 
%          y.inj.s_v, y.inj.s_l in J/kg-K).

s_kJ   = y.inj.s / 1000;   % Convert J/kg-K to kJ/kg-K
s_v_kJ = y.inj.s_v / 1000; % Convert J/kg-K to kJ/kg-K
s_l_kJ = y.inj.s_l / 1000; % Convert J/kg-K to kJ/kg-K

plot(ax, y.time, s_kJ,   'b-',  'LineWidth', 1.5, 'DisplayName', 'Mixture (s)'); 
hold(ax, 'on');
plot(ax, y.time, s_v_kJ, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Vapor (s_v)');
plot(ax, y.time, s_l_kJ, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Liquid (s_l)');
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Spec. Entropy (kJ/kg-K)');
title(ax, 'Injector Specific Entropy (Mixture, Vapor, Liquid) vs Time');
legend(ax, 'show', 'Location', 'best');

end 