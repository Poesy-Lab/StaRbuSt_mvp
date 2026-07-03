function Plot_Grain_dRm_t(ax, y)
%Plot_Grain_dRm_t Plots radius change per step (dR_m) vs time.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.dR_m).

% Check if the necessary fields exist
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'dR_m')
    warning('Plot_Grain_dRm_t:MissingData', 'Time or dR_m data not found in y structure.');
    text(ax, 0.5, 0.5, 'dR_m data not available', 'HorizontalAlignment', 'center');
    return;
end

% --- Data Extraction ---
time_s = y.time;
dR_m = y.fuel.dR_m; % Radius change in meters per step

% --- Convert dR from meters to millimeters ---
dR_mm = dR_m * 1000; % 1 m = 1000 mm

% --- Plotting ---
plot(ax, time_s, dR_mm, 'LineWidth', 1.5);
title(ax, 'Radius Change per Step (dR_m) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Radius Change per Step, dR (mm)');
grid(ax, 'on');
box(ax, 'on');

end 