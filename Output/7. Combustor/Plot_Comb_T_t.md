---
lastmod: 2025-04-30
tags:
  - plot
  - combustor
  - temperature
  - output
---

# Plot_Comb_T_t.m

연소기 온도 (`y.comb.T`) 를 K에서 °C로 변환하여 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.comb.T` (K 단위) 포함해야 함)

## 출력

지정된 `ax`에 °C 단위의 온도 그래프를 그립니다.

## 관련 파일

*   [[Components/7. Combustor/Comb_Itercalc.m|Comb_Itercalc.m]]
*   [[Output/7. Combustor/Plot_Comb_Results.m|Plot_Comb_Results.m]] (호출)

## # 전체 코드

```matlab
function Plot_Comb_T_t(ax, y)
%Plot_Comb_T_t Plots combustion temperature (T) in Celsius vs time.
%   Plots y.comb.T (converted from K to C) against y.time on the
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.T in K).

T_C = y.comb.T - 273.15; % Convert K to Celsius

plot(ax, y.time, T_C, 'k-', 'LineWidth', 1.5); % Black solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Temperature (T) (°C)');
title(ax, 'Combustion Temperature vs Time');
legend(ax, 'hide');

end
``` 