---
lastmod: 2024-07-27
tags:
  - plot
  - combustor
  - specific heat ratio
  - gamma
  - output
---

# Plot_Comb_Gamma_t.m

연소기 비열비 (`y.comb.gamma`) 를 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.comb.gamma` 포함해야 함)

## 출력

지정된 `ax`에 비열비 그래프를 그립니다.

## 관련 파일

*   [[Components/7. Combustor/Comb_param.m|Comb_param.m]]
*   [[Output/7. Combustor/Plot_Comb_Results.m|Plot_Comb_Results.m]] (호출)

## 전체 코드

```matlab
function Plot_Comb_Gamma_t(ax, y)
%Plot_Comb_Gamma_t Plots combustor specific heat ratio vs. time.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.gamma).

% Check if the required variables exist
if isfield(y, 'time') && isfield(y, 'comb') && isfield(y.comb, 'gamma')
    t = y.time;
    gamma = y.comb.gamma;

    % Filter out NaN values
    valid_indices = ~isnan(t) & ~isnan(gamma);
    t_plot = t(valid_indices);
    gamma_plot = gamma(valid_indices);

    if ~isempty(t_plot)
        plot(ax, t_plot, gamma_plot, 'LineWidth', 1.5);
        xlabel(ax, 'Time (s)');
        ylabel(ax, 'Specific Heat Ratio (-)');
        title(ax, 'Combustor Specific Heat Ratio (Gamma) vs. Time');
        grid(ax, 'on');
        % legend(ax, 'Gamma', 'Location', 'best'); % Optional legend
    else
        title(ax, 'Combustor Gamma vs. Time (No valid data to plot)');
        text(ax, 0.5, 0.5, 'No valid data points for Gamma', 'HorizontalAlignment', 'center');
    end
else
    % Handle missing fields
    title(ax, 'Combustor Gamma vs. Time (Data Missing)');
    text(ax, 0.5, 0.5, sprintf('Missing required fields:\n%s%s', ...
                            iif(~isfield(y, 'time'), 'y.time ', ''), ...
                            iif(~isfield(y, 'comb') || ~isfield(y.comb, 'gamma'), 'y.comb.gamma ', '')), ...
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
``` 