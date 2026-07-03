function Plot_Nozzle_Cf_t(ax, y)
%Plot_Nozzle_Cf_t Plots thrust coefficient (Cf) vs time.
%   Plots y.nozzle.Cf against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.nozzle.Cf).

% Extract data
time = y.time;
Cf = y.nozzle.Cf;
% Mode = y.nozzle.Mode; % No longer needed

% Plot Cf (handle NaNs)
valid_indices = find(~isnan(Cf));
if ~isempty(valid_indices)
    plot(ax, time(valid_indices), Cf(valid_indices), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Cf'); % Added DisplayName
else
    plot(ax, NaN, NaN, 'b-', 'DisplayName', 'Cf'); % Plot NaN if no data
    warning('Plot_Nozzle_Cf_t:NoValidData', 'No valid Cf data to plot.');
end

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Thrust Coefficient (Cf)');
title(ax, 'Nozzle Thrust Coefficient (Cf) vs Time');
legend(ax, 'hide'); % Hide legend by default, data tip is primary

% --- Enable Default Data Tips ---
datacursormode(ancestor(ax, 'figure')); % Enable data cursor mode

% --- Remove Custom Data Tip Configuration ---
% if ishghandle(cf_plot) && ~isempty(valid_indices) 
%     cursorMode = datacursormode(ancestor(ax, 'figure'));
%     cursorMode.Enable = 'on';
%     cursorMode.UpdateFcn = {@cfDataTipUpdateFcn, time, Cf, Mode, valid_indices};
%     set(cf_plot, 'ButtonDownFcn', '');
% end

end

% --- Removed Custom Data Tip Function ---
% function txt = cfDataTipUpdateFcn(~, event_obj, time, Cf, Mode, valid_indices)
% ... (function code removed) ...
% end 