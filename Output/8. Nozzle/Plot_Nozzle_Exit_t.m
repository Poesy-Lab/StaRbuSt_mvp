function Plot_Nozzle_Exit_t(ax, y)
%Plot_Nozzle_Exit_t Plots nozzle exit pressure (Pe), ambient pressure (Pamb)
%   vs time, using default data tips.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.nozzle.Pe, y.amb.P).

% Extract data
time = y.time;
Pe_Pa = y.nozzle.Pe;
Pamb_Pa = y.amb.P;
% Mode = y.nozzle.Mode; % No longer needed

% Ensure Pamb is the same length as time if it's scalar
if isscalar(Pamb_Pa) && ~isempty(time) % Add check for empty time
    Pamb_Pa = repmat(Pamb_Pa, size(time));
elseif isempty(Pamb_Pa) && ~isempty(time)
    Pamb_Pa = nan(size(time)); % Handle empty Pamb case
end

% --- Plot Pressures (Left Y-axis only) ---
hold(ax, 'on');

% Plot Exit Pressure (handle NaNs)
valid_Pe_indices = find(~isnan(Pe_Pa)); % Use find to get numerical indices
if ~isempty(valid_Pe_indices)
    plot(ax, time(valid_Pe_indices), Pe_Pa(valid_Pe_indices)/1e5, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Pe'); % Convert Pa to bar for plot
else
    plot(ax, NaN, NaN, 'b-', 'DisplayName', 'Pe'); % Plot NaN if no valid data
    warning('Plot_Nozzle_Exit_t:NoValidPeData', 'No valid Pe data to plot.');
end

% Plot Ambient Pressure (handle NaNs)
valid_Pamb_indices = find(~isnan(Pamb_Pa)); % Use find
if ~isempty(valid_Pamb_indices)
    plot(ax, time(valid_Pamb_indices), Pamb_Pa(valid_Pamb_indices)/1e5, 'k--', 'LineWidth', 1, 'DisplayName', 'Pamb'); % Convert Pa to bar for plot
else
     plot(ax, NaN, NaN, 'k--', 'DisplayName', 'Pamb'); % Plot NaN if no valid data
     warning('Plot_Nozzle_Exit_t:NoValidPambData', 'No valid Pamb data to plot.');
end

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Pressure (bar)'); % Label remains bar
title(ax, 'Nozzle Exit Conditions vs Time');
hold(ax, 'off');

% --- Enable Default Data Tips ---
datacursormode(ancestor(ax, 'figure')); % Enable data cursor mode

% --- Remove Custom Data Tip Configuration ---
% if ishghandle(pe_plot) && ~isempty(valid_Pe_indices) 
%     cursorMode = datacursormode(ancestor(ax, 'figure'));
%     cursorMode.Enable = 'on';
%     cursorMode.UpdateFcn = {@peDataTipUpdateFcn, time, Pe_Pa, Mode, valid_Pe_indices};
%     set(pe_plot, 'ButtonDownFcn', '');
% end

% --- Legend ---
pressurePlots = findobj(ax.Children, '-regexp', 'DisplayName', '^(Pe|Pamb)$');
if ~isempty(pressurePlots)
    legend(pressurePlots, 'Location', 'best');
else
    legend(ax, 'hide');
end

end

% --- Removed Custom Data Tip Function ---
% function txt = peDataTipUpdateFcn(~, event_obj, time, Pe_Pa, Mode, valid_Pe_indices)
% ... (function code removed) ...
% end 