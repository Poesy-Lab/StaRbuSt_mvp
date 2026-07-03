---
tags:
  - 플롯
  - 그레인
  - Ap
  - 면적
  - 포트
  - 출력
lastmod: 2025-04-30
---

# Plot_Grain_Ap_t.m

포트 면적 (`y.fuel.Ap`)을 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.fuel.Ap` 포함해야 함)

## 출력

지정된 `ax`에 그래프를 그립니다.

## 관련 파일

*   [[Output/6. Grain/Plot_Grain_Results.m|Plot_Grain_Results.m]] (호출)
*   (Ap 계산 관련 함수 - 필요시 추가)

## 전체 코드

```matlab
function Plot_Grain_Ap_t(ax, y)
%Plot_Grain_Ap_t Plots port area (Ap) vs time.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.Ap).

% Check if the necessary field exists
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'Ap')
    warning('Plot_Grain_Ap_t:MissingData', 'Time or Ap data not found in y structure.');
    text(ax, 0.5, 0.5, 'Ap data not available', 'HorizontalAlignment', 'center');
    return;
end

plot(ax, y.time, y.fuel.Ap, 'LineWidth', 1.5);
title(ax, 'Port Area (Ap) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Port Area (m^2)');
grid(ax, 'on');
box(ax, 'on');

end
``` 