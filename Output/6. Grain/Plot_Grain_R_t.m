function Plot_Grain_R_t(ax, y)
%Plot_Grain_R_t Plots port radius (R) vs time.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.R).

% Check if the necessary field exists
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'R')
    warning('Plot_Grain_R_t:MissingData', 'Time or R data not found in y structure.');
    text(ax, 0.5, 0.5, 'R data not available', 'HorizontalAlignment', 'center');
    return;
end

plot(ax, y.time, y.fuel.R * 1000, 'LineWidth', 1.5);
title(ax, 'Port Radius (R) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Port Radius (mm)');
grid(ax, 'on');
box(ax, 'on');

end 