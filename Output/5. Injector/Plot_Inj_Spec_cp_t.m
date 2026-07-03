function Plot_Inj_Spec_cp_t(ax, y)
%Plot_Inj_Spec_cp_t Plots injector spec. heat cp (mix, vap, liq) vs. time.
%   Plots y.inj.cp, cp_v, cp_l (converted to kJ/kg-K) against y.time on the
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.cp, 
%          y.inj.cp_v, y.inj.cp_l in J/kg-K).

cp_kJ   = y.inj.cp / 1000;   % Convert J/kg-K to kJ/kg-K
cp_v_kJ = y.inj.cp_v / 1000; % Convert J/kg-K to kJ/kg-K
cp_l_kJ = y.inj.cp_l / 1000; % Convert J/kg-K to kJ/kg-K

plot(ax, y.time, cp_kJ,   'b-',  'LineWidth', 1.5, 'DisplayName', 'Mixture (cp)'); 
hold(ax, 'on');
plot(ax, y.time, cp_v_kJ, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Vapor (cp_v)');
plot(ax, y.time, cp_l_kJ, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Liquid (cp_l)');
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Spec. Heat cp (kJ/kg-K)');
title(ax, 'Injector Specific Heat cp (Mixture, Vapor, Liquid) vs Time');
legend(ax, 'show', 'Location', 'best');

end 