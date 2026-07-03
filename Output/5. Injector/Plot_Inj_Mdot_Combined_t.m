function Plot_Inj_Mdot_Combined_t(ax, y)
%Plot_Inj_Mdot_Combined_t Plots total and NHNE component mass flow rates.
%   Plots y.inj.mdot (total), y.inj.mdot_inc (inc. Cd*A), and y.inj.mdot_HEM (inc. Cd*A)
%   against y.time on the provided axes ax.
%   NHNE components are calculated only during LiqFeed (using Inj_NHNE_LiqFeed.m)
%   and will be NaN during VapFeed. The plot will show gaps for these components
%   during the VapFeed phase.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.mdot, 
%          y.inj.mdot_inc (with Cd*A), y.inj.mdot_HEM (with Cd*A)).

plot(ax, y.time, y.inj.mdot,       'b-',  'LineWidth', 2.0, 'DisplayName', 'Total (mdot)');
hold(ax, 'on');
plot(ax, y.time, y.inj.mdot_inc, 'Color', [0 0.4470 0.7410], 'LineStyle', '--', 'LineWidth', 1.5, 'DisplayName', 'NHNE: mdot_{inc}');
plot(ax, y.time, y.inj.mdot_HEM, 'Color', [0.6350 0.0780 0.1840], 'LineStyle', ':', 'LineWidth', 1.5, 'DisplayName', 'NHNE: mdot_{HEM}');
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Mass Flow Rate (kg/s)');
title(ax, 'Injector Mass Flow Rates (Total & NHNE Components) vs Time');
legend(ax, 'show', 'Location', 'best');

end 