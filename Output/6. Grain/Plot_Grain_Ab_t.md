---
tags:
  - 플롯
  - 그레인
  - Ab
  - 면적
  - 연소
  - 출력
lastmod: 2025-04-30
---


# Plot_Grain_Ab_t.m

연소 면적 (`y.fuel.Ab`)을 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.fuel.Ab` 포함해야 함)

## 출력

지정된 `ax`에 그래프를 그립니다.

## 관련 파일

*   [[Output/6. Grain/Plot_Grain_Results.m|Plot_Grain_Results.m]] (호출)
*   (Ab 계산 관련 함수 - 필요시 추가)

## 전체 코드

```matlab
function Plot_Grain_Ab_t(ax, y)
%Plot_Grain_Ab_t Plots burn area (Ab) vs time.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.Ab).

% Check if the necessary field exists
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'Ab')
    warning('Plot_Grain_Ab_t:MissingData', 'Time or Ab data not found in y structure.');
    text(ax, 0.5, 0.5, 'Ab data not available', 'HorizontalAlignment', 'center');
    return;
end

plot(ax, y.time, y.fuel.Ab, 'LineWidth', 1.5);
title(ax, 'Burn Area (Ab) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Burn Area (m^2)');
grid(ax, 'on');
box(ax, 'on');

end