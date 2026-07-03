---
tags:
  - 플롯
  - 그레인
  - R
  - 반경
  - 출력
lastmod: 2024-07-31
---

# Plot_Grain_R_t.m

포트 반경 (`y.fuel.R`)을 시간에 따라 플로팅하는 함수입니다. 단위는 **mm** 입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.fuel.R` 포함해야 함, R은 m 단위로 가정)

## 출력

지정된 `ax`에 그래프를 그립니다. (mm 단위)

## 관련 파일

*   [[Components/6. Grain/Grain_aGn.m|Grain_aGn.m]]
*   [[Output/6. Grain/Plot_Grain_Results.m|Plot_Grain_Results.m]] (호출)

## 전체 코드

```matlab
function Plot_Grain_R_t(ax, y)
%Plot_Grain_R_t Plots port radius (R) vs time in millimeters.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.R in meters).

% Check if the necessary field exists
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'R')
    warning('Plot_Grain_R_t:MissingData', 'Time or R data not found in y structure.');
    text(ax, 0.5, 0.5, 'R data not available', 'HorizontalAlignment', 'center');
    return;
end

plot(ax, y.time, y.fuel.R * 1000, 'LineWidth', 1.5); % Multiply by 1000 for mm
title(ax, 'Port Radius (R) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Port Radius (mm)');
grid(ax, 'on');
box(ax, 'on');

end 