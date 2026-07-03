---
tags:
  - 플롯
  - 그레인
  - dRm
  - 반지름
  - 변화량
  - 후퇴
  - 출력
lastmod: 2024-05-01 # 오늘 날짜 또는 최종 수정일
---

# Plot_Grain_dRm_t.m

시간 단계별 연료 그레인 반지름 변화량 (`y.fuel.dR_m`, mm 단위)을 시간에 따라 플로팅하는 함수입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.fuel.dR_m` 포함해야 함)

## 출력

지정된 `ax`에 그래프를 그립니다.

## 관련 파일

*   [[Output/6. Grain/Plot_Grain_Results.m|Plot_Grain_Results.m]] (호출)
*   [[Components/6. Grain/Grain_aGn.m|Grain_aGn.m]] (dR_m 계산)

## 전체 코드

```matlab
function Plot_Grain_dRm_t(ax, y)
%Plot_Grain_dRm_t Plots radius change per step (dR_m) vs time.
%
%   Inputs:
%       ax: Axes handle for plotting.
%       y: Simulation results structure (must contain y.time and y.fuel.dR_m).

% Check if the necessary fields exist
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'dR_m')
    warning('Plot_Grain_dRm_t:MissingData', 'Time or dR_m data not found in y structure.');
    text(ax, 0.5, 0.5, 'dR_m data not available', 'HorizontalAlignment', 'center');
    return;
end

% --- Data Extraction ---
time_s = y.time;
dR_m = y.fuel.dR_m; % Radius change in meters per step

% --- Convert dR from meters to millimeters ---
dR_mm = dR_m * 1000; % 1 m = 1000 mm

% --- Plotting ---
plot(ax, time_s, dR_mm, 'LineWidth', 1.5);
title(ax, 'Radius Change per Step (dR_m) vs Time');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Radius Change per Step, dR (mm)');
grid(ax, 'on');
box(ax, 'on');

end
``` 