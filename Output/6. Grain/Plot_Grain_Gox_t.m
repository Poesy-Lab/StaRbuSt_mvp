function Plot_Grain_Gox_t(ax, y)
%Plot_Grain_Gox_t Plots oxidizer flux (Gox) vs time.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.Gox).

% Check if the necessary field exists
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'Gox')
    warning('Plot_Grain_Gox_t:MissingData', 'Time or Gox data not found in y structure.');
    text(ax, 0.5, 0.5, 'Gox data not available', 'HorizontalAlignment', 'center');
    return;
end

plot(ax, y.time, y.fuel.Gox, 'LineWidth', 1.5);
title(ax, 'Oxidizer Mass Flux (Gox) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Gox (kg/m^2-s)');
grid(ax, 'on');
box(ax, 'on');

end 