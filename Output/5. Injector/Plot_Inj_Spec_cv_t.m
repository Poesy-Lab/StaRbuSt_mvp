function Plot_Inj_Spec_cv_t(ax, y)
%Plot_Inj_Spec_cv_t Plots injector spec. heat cv (mix, vap, liq) vs. time.
%   Plots y.inj.cv, cv_v, cv_l (converted to kJ/kg-K) against y.time on the
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.cv, 
%          y.inj.cv_v, y.inj.cv_l in J/kg-K).

cv_kJ   = y.inj.cv / 1000;   % Convert J/kg-K to kJ/kg-K
cv_v_kJ = y.inj.cv_v / 1000; % Convert J/kg-K to kJ/kg-K
cv_l_kJ = y.inj.cv_l / 1000; % Convert J/kg-K to kJ/kg-K

plot(ax, y.time, cv_kJ,   'b-',  'LineWidth', 1.5, 'DisplayName', 'Mixture (cv)'); 
hold(ax, 'on');
plot(ax, y.time, cv_v_kJ, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Vapor (cv_v)');
plot(ax, y.time, cv_l_kJ, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Liquid (cv_l)');
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Spec. Heat cv (kJ/kg-K)');
title(ax, 'Injector Specific Heat cv (Mixture, Vapor, Liquid) vs Time');
legend(ax, 'show', 'Location', 'best');

end 