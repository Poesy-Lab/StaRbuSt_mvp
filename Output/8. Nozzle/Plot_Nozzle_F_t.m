function Plot_Nozzle_F_t(ax, y)
%Plot_Nozzle_F_t Plots thrust (F) in N vs time.
%   Plots y.nozzle.F against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.nozzle.F).

% Extract data
time = y.time;
F = y.nozzle.F;
% Mode = y.nozzle.Mode; % No longer needed

% Plot F (handle NaNs)
valid_indices = find(~isnan(F));
if ~isempty(valid_indices)
    plot(ax, time(valid_indices), F(valid_indices), 'r-', 'LineWidth', 1.5, 'DisplayName', 'Thrust'); % Added DisplayName
else
    plot(ax, NaN, NaN, 'r-', 'DisplayName', 'Thrust'); % Plot NaN if no data
    warning('Plot_Nozzle_F_t:NoValidData', 'No valid F data to plot.');
end

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Thrust (F) (N)');
title(ax, 'Nozzle Thrust vs Time');
legend(ax, 'hide'); % Hide legend by default

% Calculate Total Impulse and Average Thrusts
if ~isempty(valid_indices) && length(valid_indices) > 1
    F_valid = F(valid_indices);
    time_valid = time(valid_indices);
    total_impulse = trapz(time_valid, F_valid);

    % Initialize thrust values
    overall_avg_thrust = NaN;
    liquid_feed_avg_thrust = NaN;
    thrust_calculated = false; % Flag to check if any thrust calculation was possible

    if max(F_valid) > 0
        % Define threshold for burn start/end
        thrust_threshold = 0.01 * max(F_valid); % Use 1% of max thrust
        burn_indices = find(F_valid > thrust_threshold);

        if length(burn_indices) > 1
            t_start_burn = time_valid(burn_indices(1));
            t_end_burn = time_valid(burn_indices(end));
            overall_burn_time = t_end_burn - t_start_burn;

            % --- Calculate Overall Average Thrust ---
            if overall_burn_time > 0
                overall_avg_thrust = total_impulse / overall_burn_time;
                thrust_calculated = true;
            else
                warning('Plot_Nozzle_F_t:ZeroOverallBurnTime', 'Overall burn time is zero or negative. Cannot calculate overall average thrust.');
            end

            % --- Calculate Liquid Feed Average Thrust ---
            [~, idx_peak] = max(F_valid); % Find index of peak thrust within valid data
            
            % Only calculate if peak is not the last point and there are points after peak
            if idx_peak < length(F_valid) && length(F_valid(idx_peak+1:end)) > 1
                % Calculate gradient after peak thrust
                thrust_gradient = diff(F_valid(idx_peak:end)) ./ diff(time_valid(idx_peak:end));
                [min_grad, idx_min_grad_rel] = min(thrust_gradient);

                % Index relative to the start of the gradient calculation (idx_peak)
                % The point *before* the steepest drop starts at idx_peak + idx_min_grad_rel - 1
                idx_liquid_end = idx_peak + idx_min_grad_rel - 1;

                % Ensure the end index is valid and after the start index
                idx_burn_start_in_valid = find(time_valid == t_start_burn, 1); % Find index of t_start_burn in time_valid

                if idx_liquid_end > idx_burn_start_in_valid
                    liquid_phase_indices = idx_burn_start_in_valid:idx_liquid_end;
                    time_liquid = time_valid(liquid_phase_indices);
                    F_liquid = F_valid(liquid_phase_indices);

                    if length(time_liquid) > 1
                        liquid_feed_impulse = trapz(time_liquid, F_liquid);
                        liquid_feed_burn_time = time_liquid(end) - time_liquid(1);

                        if liquid_feed_burn_time > 0
                            liquid_feed_avg_thrust = liquid_feed_impulse / liquid_feed_burn_time;
                            % thrust_calculated is already true if overall was calculated
                        else
                             warning('Plot_Nozzle_F_t:ZeroLiquidFeedBurnTime', 'Liquid feed burn time is zero. Cannot calculate liquid feed average thrust.');
                        end
                    else
                        warning('Plot_Nozzle_F_t:InsufficientLiquidFeedData', 'Not enough data points for liquid feed calculation.');
                    end
                else
                     warning('Plot_Nozzle_F_t:LiquidFeedEndBeforeStart', 'Calculated liquid feed end time is before start time.');
                end
            else
                 warning('Plot_Nozzle_F_t:PeakAtEnd', 'Peak thrust occurs at or near the end of data. Cannot determine liquid feed reliably.');
            end
        else
            warning('Plot_Nozzle_F_t:InsufficientBurnData', 'Not enough data points above threshold to calculate burn time and average thrust.');
        end
    else
        warning('Plot_Nozzle_F_t:ZeroThrust', 'Maximum thrust is zero. Cannot calculate average thrust.');
    end

    % --- Prepare text for display ---
    display_text = {}; % Initialize as cell array
    display_text{end+1} = sprintf('Total Impulse = %.2f Ns', total_impulse);

    if ~isnan(liquid_feed_avg_thrust)
        display_text{end+1} = sprintf('Liquid Feed Avg Thrust = %.2f N', liquid_feed_avg_thrust);
    end
    if ~isnan(overall_avg_thrust)
         display_text{end+1} = sprintf('Overall Avg Thrust = %.2f N', overall_avg_thrust);
    end


    % --- Display Text on the plot (top-right corner) ---
    if ~isempty(display_text)
        text(ax, max(xlim(ax)), max(ylim(ax)), display_text, ...
            'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
            'FontSize', 9, 'BackgroundColor', 'white', 'EdgeColor', 'black', ...
            'Interpreter', 'none'); % Use 'none' interpreter to avoid issues with special chars
    end


elseif ~isempty(valid_indices) && length(valid_indices) == 1
    warning('Plot_Nozzle_F_t:SingleDataPoint', 'Cannot calculate total impulse or average thrust with only one data point.');
end

% --- Enable Default Data Tips ---
datacursormode(ancestor(ax, 'figure')); % Enable data cursor mode

% --- Remove Custom Data Tip Configuration ---
% if ishghandle(f_plot) && ~isempty(valid_indices) 
%     cursorMode = datacursormode(ancestor(ax, 'figure'));
%     cursorMode.Enable = 'on';
%     cursorMode.UpdateFcn = {@fDataTipUpdateFcn, time, F, Mode, valid_indices};
%     set(f_plot, 'ButtonDownFcn', '');
% end

end

% --- Removed Custom Data Tip Function ---
% function txt = fDataTipUpdateFcn(~, event_obj, time, F, Mode, valid_indices)
% ... (function code removed) ...
% end 