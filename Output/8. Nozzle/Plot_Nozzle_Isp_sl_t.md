---
lastmod: 2025-04-30
tags:
  - plot
  - nozzle
  - isp
  - specific impulse
  - output
---

# Plot_Nozzle_Isp_sl_t.m

노즐 해수면 비추력 (`y.nozzle.Isp_sl`) 를 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.nozzle.Isp_sl` 포함해야 함)

## 출력

지정된 `ax`에 그래프를 그립니다.

## 관련 파일

*   [[Components/8. Nozzle/Nozzle.m|Nozzle.m]]
*   [[Output/8. Nozzle/Plot_Nozzle_Results.m|Plot_Nozzle_Results.m]] (호출)

## # 전체 코드

```matlab
function Plot_Nozzle_Isp_sl_t(ax, y)
%Plot_Nozzle_Isp_sl_t Plots sea level specific impulse (Isp_sl) vs time.
%   Plots y.nozzle.Isp_sl against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.nozzle.Isp_sl).

plot(ax, y.time, y.nozzle.Isp_sl, 'g-', 'LineWidth', 1.5); % Green solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Sea Level Specific Impulse (Isp_{sl}) (s)');
title(ax, 'Nozzle Sea Level Specific Impulse vs Time');
legend(ax, 'hide');

end
``` 