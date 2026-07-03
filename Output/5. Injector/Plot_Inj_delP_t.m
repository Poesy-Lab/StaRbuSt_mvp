function Plot_Inj_delP_t(ax, y)
%Plot_Inj_delP_t Plots the injector pressure drop vs. time.
%   Calculates the difference between tank pressure (y.tank.P) and 
%   injector outlet pressure (y.inj.P), converts it to bar, 
%   and plots it against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.tank.P, y.inj.P in Pa).

% Calculate pressure drop
del_P_Pa = y.tank.P - y.inj.P; 

% Convert Pa to bar
del_P_bar = del_P_Pa / 1e5; 

plot(ax, y.time, del_P_bar, 'm-', 'LineWidth', 1.5); % Magenta solid line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Pressure Drop (bar)');
title(ax, 'Injector Pressure Drop vs Time');

end 