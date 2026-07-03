function Plot_Grain_Ab_t(ax, y)
%Plot_Grain_Ab_t Plots burn area (Ab) vs time.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.Ab).

% Check if the necessary field exists
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'Ab')
    warning('Plot_Grain_Ab_t:MissingData', 'Time or Ab data not found in y structure.');
    text(ax, 0.5, 0.5, 'Ab data not available', 'HorizontalAlignment', 'center');
    return;
end

plot(ax, y.time, y.fuel.Ab, 'LineWidth', 1.5);
title(ax, 'Burn Area (Ab) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Burn Area (m^2)');
grid(ax, 'on');
box(ax, 'on');

end 