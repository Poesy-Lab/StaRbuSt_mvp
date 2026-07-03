function Plot_Nozzle_Isp_sl_t(ax, y)
%Plot_Nozzle_Isp_sl_t Plots sea level Isp (Isp_sl) vs time.
%   Plots y.nozzle.Isp_sl against y.time on the provided axes ax.
%   Also calculates and displays average Isp_sl for overall and liquid feed phases.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.nozzle.Isp_sl, y.nozzle.F).

% Extract data
time = y.time;
Isp_sl = y.nozzle.Isp_sl;
F = y.nozzle.F; % Need thrust data to determine phases

% Plot Isp_sl (handle NaNs)
valid_indices_isp = find(~isnan(Isp_sl));
if ~isempty(valid_indices_isp)
    plot(ax, time(valid_indices_isp), Isp_sl(valid_indices_isp), 'g-', 'LineWidth', 1.5, 'DisplayName', 'Isp_{sl}');
else
    plot(ax, NaN, NaN, 'g-', 'DisplayName', 'Isp_{sl}'); % Plot NaN if no data
    warning('Plot_Nozzle_Isp_sl_t:NoValidIspData', 'No valid Isp_sl data to plot.');
end

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Sea Level Specific Impulse (Isp_{sl}) (s)');
title(ax, 'Nozzle Sea Level Specific Impulse vs Time');
legend(ax, 'hide'); % Hide legend by default

% --- Calculate Average Isp_sl --- 
overall_avg_isp = NaN;
liquid_feed_avg_isp = NaN;

% Use thrust data to find burn phases
valid_indices_f = find(~isnan(F));
if ~isempty(valid_indices_f) && length(valid_indices_f) > 1
    F_valid = F(valid_indices_f);
    time_valid_f = time(valid_indices_f);

    if max(F_valid) > 0
        thrust_threshold = 0.01 * max(F_valid);
        burn_indices_f = find(F_valid > thrust_threshold);

        if length(burn_indices_f) > 1
            t_start_burn = time_valid_f(burn_indices_f(1));
            t_end_burn = time_valid_f(burn_indices_f(end));

            % Find Isp data within the overall burn time
            overall_isp_indices = valid_indices_isp(time(valid_indices_isp) >= t_start_burn & time(valid_indices_isp) <= t_end_burn);
            if ~isempty(overall_isp_indices)
                overall_avg_isp = mean(Isp_sl(overall_isp_indices));
            else
                 warning('Plot_Nozzle_Isp_sl_t:NoIspInDataOverall', 'No valid Isp_sl data found within the overall burn phase defined by thrust.');
            end

            % Find end of liquid feed phase based on thrust gradient
            [~, idx_peak_f] = max(F_valid);
            t_liquid_feed_end = NaN;
            if idx_peak_f < length(F_valid) && length(F_valid(idx_peak_f+1:end)) > 1
                 thrust_gradient = diff(F_valid(idx_peak_f:end)) ./ diff(time_valid_f(idx_peak_f:end));
                 [~, idx_min_grad_rel] = min(thrust_gradient);
                 idx_liquid_end_f = idx_peak_f + idx_min_grad_rel - 1;
                 if idx_liquid_end_f >= 1 && idx_liquid_end_f <= length(time_valid_f)
                     t_liquid_feed_end = time_valid_f(idx_liquid_end_f);
                 end
            end
            
            % Find Isp data within the liquid feed phase
            if ~isnan(t_liquid_feed_end) && t_liquid_feed_end > t_start_burn
                liquid_isp_indices = valid_indices_isp(time(valid_indices_isp) >= t_start_burn & time(valid_indices_isp) <= t_liquid_feed_end);
                if ~isempty(liquid_isp_indices)
                    liquid_feed_avg_isp = mean(Isp_sl(liquid_isp_indices));
                else
                    warning('Plot_Nozzle_Isp_sl_t:NoIspInDataLiquid', 'No valid Isp_sl data found within the liquid feed phase defined by thrust.');
                end
            else
                 warning('Plot_Nozzle_Isp_sl_t:CannotDetermineLiquidPhase', 'Could not reliably determine liquid feed phase end time from thrust data.');
            end
        end
    end
end

% --- Prepare text for display ---
display_text = {}; % Initialize as cell array
if ~isnan(liquid_feed_avg_isp)
    display_text{end+1} = sprintf('Liquid Feed Avg Isp_{sl} = %.2f s', liquid_feed_avg_isp);
end
if ~isnan(overall_avg_isp)
     display_text{end+1} = sprintf('Overall Avg Isp_{sl} = %.2f s', overall_avg_isp);
end

% --- Display Text on the plot (top-right corner) ---
if ~isempty(display_text)
    text(ax, max(xlim(ax)), max(ylim(ax)), display_text, ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
        'FontSize', 9, 'BackgroundColor', 'white', 'EdgeColor', 'black', ...
        'Interpreter', 'tex'); % Use tex interpreter for subscript
end

% --- Enable Default Data Tips ---
datacursormode(ancestor(ax, 'figure')); % Enable data cursor mode

% --- Removed Custom Data Tip Function ---
% function txt = ispDataTipUpdateFcn(~, event_obj, time, Isp_sl, Mode, valid_indices)
% ... (function code removed) ...
% end 