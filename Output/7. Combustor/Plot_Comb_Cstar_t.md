---
lastmod: 2025-04-30
tags:
  - plot
  - combustor
  - cstar
  - efficiency
  - output
---

# Plot_Comb_Cstar_t.m

연소기 **이론적 특성 속도** (`y.comb.cstar`, 실선)와 **연소 효율이 적용된 실제 특성 속도** (`y.comb.cstar .* y.comb.eta_cstar`, 점선) 를 시간에 따라 함께 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.comb.cstar`, `y.comb.eta_cstar` 포함해야 함)

## 출력

지정된 `ax`에 이론적 및 실제 c* 그래프를 그리고 범례(legend)를 표시합니다.

## 관련 파일

*   [[Components/7. Combustor/Comb_Itercalc.m|Comb_Itercalc.m]]
*   [[System/System.m|System.m]] (`eta_cstar` 로깅 추가)
*   [[Output/7. Combustor/Plot_Comb_Results.m|Plot_Comb_Results.m]] (호출)

## # 전체 코드

```matlab
function Plot_Comb_Cstar_t(ax, y)
%Plot_Comb_Cstar_t Plots theoretical and actual characteristic velocity (cstar) vs time.
%   Plots y.comb.cstar (theoretical, solid line) and 
%   y.comb.cstar .* y.comb.eta (actual, dashed line) against y.time 
%   on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.cstar, y.comb.eta).

% Calculate actual cstar
cstar_actual = NaN(size(y.comb.cstar)); % Pre-allocate with NaN
if isfield(y.comb, 'eta') && ~isempty(y.comb.eta)
    % Only calculate if eta exists and is not empty
    valid_idx = ~isnan(y.comb.cstar) & ~isnan(y.comb.eta);
    cstar_actual(valid_idx) = y.comb.cstar(valid_idx) .* y.comb.eta(valid_idx);
else
    warning('Plot_Comb_Cstar_t:MissingEta', 'y.comb.eta not found or empty. Skipping actual c* calculation.');
end

plot(ax, y.time, y.comb.cstar, 'm-', 'LineWidth', 1.5, 'DisplayName', 'Theoretical c*'); % Magenta solid line
hold(ax, 'on');
plot(ax, y.time, cstar_actual, 'm--', 'LineWidth', 1.5, 'DisplayName', 'Actual c* (with \eta)'); % Magenta dashed line
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Characteristic Velocity (c*) (m/s)');
title(ax, 'Combustor Characteristic Velocity (Theoretical & Actual) vs Time');
legend(ax, 'show', 'Location', 'best'); % Show legend

end
``` 