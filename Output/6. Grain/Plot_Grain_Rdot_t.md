---
lastmod: 2024-07-31
tags:
  - 플롯
  - 그레인
  - 후퇴율
  - rdot
  - 출력
---

# Plot_Grain_Rdot_t.m

연료 후퇴율 (`y.fuel.rdot`)을 시간에 따라 플로팅하는 함수입니다. 단위는 **mm/s** 입니다.

## 입력

*   `ax`: 플로팅할 axes 핸들
*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.fuel.rdot` 포함해야 함)

## 출력

지정된 `ax`에 그래프를 그립니다.

## 관련 파일

*   [[Components/6. Grain/Grain_aGn.m|Grain_aGn.m]]
*   [[Output/6. Grain/Plot_Grain_Results.m|Plot_Grain_Results.m]] (호출)

## # 전체 코드

```matlab
function Plot_Grain_Rdot_t(ax, y)
%Plot_Grain_Rdot_t Plots regression rate (rdot) vs time.
%   Plots y.fuel.rdot against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.fuel.rdot).

% Check if the necessary field exists
if ~isfield(y, 'time') || ~isfield(y, 'fuel') || ~isfield(y.fuel, 'rdot')
    warning('Plot_Grain_Rdot_t:MissingData', 'Time or rdot data not found in y structure.');
    text(ax, 0.5, 0.5, 'rdot data not available', 'HorizontalAlignment', 'center');
    return;
end

plot(ax, y.time, y.fuel.rdot, 'r-', 'LineWidth', 1.5); % Red solid line

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Regression Rate (mm/s)');
title(ax, 'Regression Rate (rdot) vs Time');
legend(ax, 'hide');

end
``` 