function Plot_Grain_Rdot_t(ax, y)
%Plot_Grain_Rdot_t Plots regression rate (rdot) vs time.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.rdot).

% Check if the necessary field exists
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'rdot')
    warning('Plot_Grain_Rdot_t:MissingData', 'Time or rdot data not found in y structure.');
    text(ax, 0.5, 0.5, 'rdot data not available', 'HorizontalAlignment', 'center');
    return;
end

plot(ax, y.time, y.fuel.rdot, 'LineWidth', 1.5);
title(ax, 'Fuel Regression Rate (rdot) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Regression Rate (mm/s)');
grid(ax, 'on');
box(ax, 'on');

end 