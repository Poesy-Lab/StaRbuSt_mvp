---
lastmod: 2025-04-30
tags:
  - plot
  - grain
  - gox
  - output
---


# Plot_Grain_Gox_t.m

Oxidizer mass flux (`y.fuel.Gox`) 를 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.fuel.Gox` 포함해야 함)

## 출력

지정된 `ax`에 그래프를 그립니다.

## 관련 파일

*   [[Components/6. Grain/Grain_aGn.m|Grain_aGn.m]]
*   [[Output/6. Grain/Plot_Grain_Results.m|Plot_Grain_Results.m]] (호출)

## # 전체 코드

```matlab
function Plot_Grain_Gox_t(ax, y)
%Plot_Grain_Gox_t Plots oxidizer mass flux (Gox) vs time.
%   Plots y.fuel.Gox against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.fuel.Gox).

plot(ax, y.time, y.fuel.Gox, 'g-', 'LineWidth', 1.5); % Green solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Oxidizer Mass Flux (Gox) (kg/m^2-s)');
title(ax, 'Oxidizer Mass Flux (Gox) vs Time');
legend(ax, 'hide'); % Hide legend if only one line

end
``` 