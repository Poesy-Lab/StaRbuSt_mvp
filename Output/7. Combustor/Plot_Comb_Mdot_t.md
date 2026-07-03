---
lastmod: 2025-04-30
tags:
  - plot
  - combustor
  - mdot
  - output
---

# Plot_Comb_Mdot_t.m

연소기 총 질량 유량 (`y.comb.mdot`) 을 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.comb.mdot` 포함해야 함)

## 출력

지정된 `ax`에 그래프를 그립니다.

## 관련 파일

*   [[Components/7. Combustor/Comb_Itercalc.m|Comb_Itercalc.m]]
*   [[Output/7. Combustor/Plot_Comb_Results.m|Plot_Comb_Results.m]] (호출)

## # 전체 코드

```matlab
function Plot_Comb_Mdot_t(ax, y)
%Plot_Comb_Mdot_t Plots total mass flow rate through combustor vs time.
%   Plots y.comb.mdot against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.comb.mdot).

plot(ax, y.time, y.comb.mdot, 'b-', 'LineWidth', 1.5); % Blue solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Mass Flow Rate (mdot) (kg/s)');
title(ax, 'Combustor Mass Flow Rate vs Time');
legend(ax, 'hide');

end
``` 