---
lastmod: 2025-04-30
tags:
  - plot
  - grain
  - mdot
  - output
---


# Plot_Grain_Mdot_t.m

Fuel mass flow rate (`y.fuel.mdot`) 를 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.fuel.mdot` 포함해야 함)

## 출력

지정된 `ax`에 그래프를 그립니다.

## 관련 파일

*   [[Components/6. Grain/Grain_aGn.m|Grain_aGn.m]]
*   [[Output/6. Grain/Plot_Grain_Results.m|Plot_Grain_Results.m]] (호출)

## # 전체 코드

```matlab
function Plot_Grain_Mdot_t(ax, y)
%Plot_Grain_Mdot_t Plots fuel mass flow rate (mdot) vs time.
%   Plots y.fuel.mdot against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.fuel.mdot).

plot(ax, y.time, y.fuel.mdot, 'b-', 'LineWidth', 1.5); % Blue solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Fuel Mass Flow Rate (mdot) (kg/s)');
title(ax, 'Fuel Mass Flow Rate (mdot) vs Time');
legend(ax, 'hide');

end
``` 