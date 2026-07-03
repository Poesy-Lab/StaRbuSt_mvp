---
lastmod: 2025-04-30
tags:
  - plot
  - combustor
  - of
  - output
---

# Plot_Comb_OF_t.m

연소기 혼합비 (O/F ratio, `y.comb.OF`) 를 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.comb.OF` 포함해야 함)

## 출력

지정된 `ax`에 그래프를 그립니다.

## 관련 파일

*   [[Components/7. Combustor/Comb_Itercalc.m|Comb_Itercalc.m]]
*   [[Output/7. Combustor/Plot_Comb_Results.m|Plot_Comb_Results.m]] (호출)

## # 전체 코드

```matlab
function Plot_Comb_OF_t(ax, y)
%Plot_Comb_OF_t Plots O/F ratio in combustor vs time.
%   Plots y.comb.OF against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.OF).

plot(ax, y.time, y.comb.OF, 'm-', 'LineWidth', 1.5); % Magenta solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'O/F Ratio');
title(ax, 'Combustor O/F Ratio vs Time');
legend(ax, 'hide');

end
``` 