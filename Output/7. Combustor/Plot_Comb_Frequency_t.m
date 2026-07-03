function Plot_Comb_Frequency_t(ax, y)
%Plot_Comb_Frequency_t Plots combustion chamber acoustic frequencies vs time.
%   Plots y.comb.f_L1, y.comb.f_L2, y.comb.f_H_pre_chamber, 
%   y.comb.f_H_overall, and y.comb.f_HL against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time and relevant 
%          frequency fields in y.comb, e.g., f_L1, f_L2, f_H_pre_chamber, f_H_overall, f_HL).

% Check for necessary fields
fields_to_check = {'f_L1', 'f_L2', 'f_H_pre_chamber', 'f_H_overall', 'f_HL'};
legends = {'LAM 1st', 'LAM 2nd', 'Helmholtz (Pre-Ch)', 'Helmholtz (Overall)', 'HLFM'};
colors = {'b-', 'r-', 'g-', 'm-', 'k--'}; % Blue, Red, Green, Magenta, Black Dashed
plotted_anything = false;

hold(ax, 'on');

for i = 1:length(fields_to_check)
    field_name = fields_to_check{i};
    if isfield(y.comb, field_name) && ~isempty(y.comb.(field_name)) && any(~isnan(y.comb.(field_name)))
        plot(ax, y.time, y.comb.(field_name), colors{i}, 'LineWidth', 1.5, 'DisplayName', legends{i});
        plotted_anything = true;
    else
        warning('Plot_Comb_Frequency_t:MissingData', 'Data for y.comb.%s not found or all NaN. Skipping plot.', field_name);
    end
end

hold(ax, 'off');

if plotted_anything
    grid(ax, 'on');
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Frequency (Hz)');
    title(ax, 'Combustion Chamber Acoustic Frequencies vs Time');
    legend(ax, 'show', 'Location', 'best');
else
    title(ax, 'Combustion Chamber Acoustic Frequencies vs Time (No data to plot)');
    legend(ax, 'hide'); % Hide legend if nothing was plotted
end

end
