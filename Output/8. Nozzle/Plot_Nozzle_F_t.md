---
lastmod: 2025-04-30
tags:
  - plot
  - nozzle
  - thrust
  - output
---

# Plot_Nozzle_F_t.m

노즐 추력 (`y.nozzle.F`) 를 N 단위로 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.nozzle.F` (N 단위) 포함해야 함)

## 출력

지정된 `ax`에 N 단위의 추력 그래프를 그립니다.

## 관련 파일

*   [[Components/8. Nozzle/Nozzle.m|Nozzle.m]]
*   [[Output/8. Nozzle/Plot_Nozzle_Results.m|Plot_Nozzle_Results.m]] (호출)

## # 전체 코드

```matlab
function Plot_Nozzle_F_t(ax, y)
%Plot_Nozzle_F_t Plots thrust (F) in N vs time.
%   Plots y.nozzle.F against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.nozzle.F in N).

% F_kN = y.nozzle.F / 1000; % Convert N to kN (Removed)

plot(ax, y.time, y.nozzle.F, 'r-', 'LineWidth', 1.5); % Plot directly in N

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Thrust (F) (N)'); % Updated unit to N
title(ax, 'Nozzle Thrust vs Time');
legend(ax, 'hide');

end
``` 