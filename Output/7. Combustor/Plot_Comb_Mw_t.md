---
lastmod: 2024-07-27
tags:
  - plot
  - combustor
  - molecular weight
  - mw
  - output
---

# Plot_Comb_Mw_t.m

연소기 분자량 (`y.comb.mw`) 를 kg/kmol 단위로 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.comb.mw` (kg/kmol 단위) 포함해야 함)

## 출력

지정된 `ax`에 kg/kmol 단위의 분자량 그래프를 그립니다.

## 관련 파일

*   [[Components/7. Combustor/Comb_param.m|Comb_param.m]]
*   [[Output/7. Combustor/Plot_Comb_Results.m|Plot_Comb_Results.m]] (호출)

## 전체 코드

```matlab
function Plot_Comb_Mw_t(ax, y)
%Plot_Comb_Mw_t Plots combustor molecular weight vs. time.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.mw).

% Check if the required variables exist
if isfield(y, 'time') && isfield(y, 'comb') && isfield(y.comb, 'mw')
    t = y.time;
    mw = y.comb.mw;

    % Filter out NaN values to avoid plotting issues, especially if simulation stopped early
    valid_indices = ~isnan(t) & ~isnan(mw);
    t_plot = t(valid_indices);
    mw_plot = mw(valid_indices);

    if ~isempty(t_plot)
        plot(ax, t_plot, mw_plot, 'LineWidth', 1.5);
        xlabel(ax, 'Time (s)');
        ylabel(ax, 'Molecular Weight (kg/kmol)');
        title(ax, 'Combustor Molecular Weight vs. Time');
        grid(ax, 'on');
        % legend(ax, 'Mw', 'Location', 'best'); % Optional legend
    else
        title(ax, 'Combustor Mw vs. Time (No valid data to plot)');
        text(ax, 0.5, 0.5, 'No valid data points for Mw', 'HorizontalAlignment', 'center');
    end
else
    % Handle missing fields by displaying a message on the plot
    title(ax, 'Combustor Mw vs. Time (Data Missing)');
    text(ax, 0.5, 0.5, sprintf('Missing required fields:\n%s%s', ...
                            iif(~isfield(y, 'time'), 'y.time ', ''), ...
                            iif(~isfield(y, 'comb') || ~isfield(y.comb, 'mw'), 'y.comb.mw ', '')), ...
         'HorizontalAlignment', 'center');
end

% Helper for conditional string in text (inline if)
function out = iif(condition, true_str, false_str)
    if condition
        out = true_str;
    else
        out = false_str;
    end
end

end 