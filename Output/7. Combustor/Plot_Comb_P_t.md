---
lastmod: 2025-04-30
tags:
  - plot
  - combustor
  - pressure
  - output
---

# Plot_Comb_P_t.m

연소기 압력 (`y.comb.P`) 를 Pa에서 bar로 변환하여 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.comb.P` (Pa 단위) 포함해야 함)

## 출력

지정된 `ax`에 bar 단위의 압력 그래프를 그립니다.

## 관련 파일

*   [[Components/7. Combustor/Comb_Itercalc.m|Comb_Itercalc.m]]
*   [[Output/7. Combustor/Plot_Comb_Results.m|Plot_Comb_Results.m]] (호출)

## # 전체 코드

```matlab
function Plot_Comb_P_t(ax, y)
%Plot_Comb_P_t Plots combustion pressure (P) in bar vs time.
%   Plots y.comb.P (converted from Pa to bar) against y.time on the
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.P in Pa).

P_bar = y.comb.P / 1e5; % Convert Pa to bar

plot(ax, y.time, P_bar, 'r-', 'LineWidth', 1.5); % Red solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Pressure (P) (bar)');
title(ax, 'Combustion Pressure vs Time');
legend(ax, 'hide');

end
``` 