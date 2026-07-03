---
lastmod: 2024-07-27
tags:
  - plot
  - combustor
  - density
  - rho_c
  - output
---

# Plot_Comb_Rho_c_t.m

연소실 밀도 (`y.comb.rho_c`) 를 kg/m³ 단위로 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.comb.rho_c` (kg/m³ 단위) 포함해야 함)

## 출력

지정된 `ax`에 kg/m³ 단위의 밀도 그래프를 그립니다.

## 관련 파일

*   [[Components/7. Combustor/Comb_param.m|Comb_param.m]]
*   [[Output/7. Combustor/Plot_Comb_Results.m|Plot_Comb_Results.m]] (호출)

## 전체 코드

```matlab
function Plot_Comb_Rho_c_t(ax, y)
%Plot_Comb_Rho_c_t Plots combustor chamber density vs. time.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.rho_c).

% Check if the required variables exist
if isfield(y, 'time') && isfield(y, 'comb') && isfield(y.comb, 'rho_c')
    t = y.time;
    rho_c = y.comb.rho_c;

    % Filter out NaN values
    valid_indices = ~isnan(t) & ~isnan(rho_c);
    t_plot = t(valid_indices);
    rho_c_plot = rho_c(valid_indices);

    if ~isempty(t_plot)
        plot(ax, t_plot, rho_c_plot, 'LineWidth', 1.5);
        xlabel(ax, 'Time (s)');
        ylabel(ax, 'Chamber Density (kg/m^3)');
        title(ax, 'Combustor Chamber Density vs. Time');
        grid(ax, 'on');
        % legend(ax, 'rho_c', 'Location', 'best'); % Optional legend
    else
        title(ax, 'Combustor rho_c vs. Time (No valid data to plot)');
        text(ax, 0.5, 0.5, 'No valid data points for rho_c', 'HorizontalAlignment', 'center');
    end
else
    % Handle missing fields
    title(ax, 'Combustor rho_c vs. Time (Data Missing)');
    text(ax, 0.5, 0.5, sprintf('Missing required fields:\n%s%s', ...
                            iif(~isfield(y, 'time'), 'y.time ', ''), ...
                            iif(~isfield(y, 'comb') || ~isfield(y.comb, 'rho_c'), 'y.comb.rho_c ', '')), ...
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