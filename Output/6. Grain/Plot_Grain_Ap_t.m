function Plot_Grain_Ap_t(ax, y)
%Plot_Grain_Ap_t Plots port area (Ap) vs time.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.Ap).

% Check if the necessary field exists
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'Ap')
    warning('Plot_Grain_Ap_t:MissingData', 'Time or Ap data not found in y structure.');
    text(ax, 0.5, 0.5, 'Ap data not available', 'HorizontalAlignment', 'center');
    return;
end

plot(ax, y.time, y.fuel.Ap, 'LineWidth', 1.5);
title(ax, 'Port Area (Ap) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Port Area (m^2)');
grid(ax, 'on');
box(ax, 'on');

end 