function Plot_Nozzle_Pt_t(ax, y)
%Plot_Nozzle_Pt_t Plots nozzle throat pressure (Pt) vs time.
%   Plots y.nozzle.Pt against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.nozzle.Pt).

% Extract data
time = y.time;
Pt = y.nozzle.Pt; % Use Pt (Nozzle Throat Pressure)

% Plot Pt (handle NaNs)
valid_indices = find(~isnan(Pt));
if ~isempty(valid_indices)
    plot(ax, time(valid_indices), Pt(valid_indices) / 1e5, 'm-', 'LineWidth', 1.5, 'DisplayName', 'Pt (bar)'); % Convert Pa to bar for plotting
else
    plot(ax, NaN, NaN, 'm-', 'DisplayName', 'Pt (bar)'); % Plot NaN if no data
    warning('Plot_Nozzle_Pt_t:NoValidData', 'No valid Pt data to plot.');
end

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Throat Pressure (Pt, bar)'); % Updated Y-axis label
title(ax, 'Nozzle Throat Pressure (Pt) vs Time');
legend(ax, 'hide'); % Hide legend by default, data tip is primary

% --- Enable Default Data Tips ---
datacursormode(ancestor(ax, 'figure')); % Enable data cursor mode

end 