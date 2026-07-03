---
tags:
  - 플롯
  - 탱크
  - 질량
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Tank_m_t.m` 문서

## 함수 개요

`Plot_Tank_m_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 탱크 내 총 질량, 증기 질량, 액체 질량 변화를 플롯합니다.

```matlab
function Plot_Tank_m_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.tank.m`, `y.tank.m_v`, `y.tank.m_l` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.tank.m` (총 질량, 단위: kg)
    -   `y.tank.m_v` (증기 질량, 단위: kg)
    -   `y.tank.m_l` (액체 질량, 단위: kg)

## 설명

`ax`로 지정된 `uiaxes` 객체에 총 질량(`m`), 증기 질량(`m_v`), 액체 질량(`m_l`)을 `y.time`에 대해 플롯합니다.

-   **플롯 스타일:**
    -   총 질량: 파란색 실선 (`b-`), 선 굵기 1.5
    -   증기 질량: 빨간색 파선 (`r--`)
    -   액체 질량: 검정색 점선 (`k:`)
-   **부가 기능:** 그리드 표시, 범례 표시, 축 레이블 및 제목 설정.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Tank_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabM = uitab(tabGroup, 'Title', 'Mass');
axM = uiaxes(tabM, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Tank_m_t(axM, y);
```

## 관련 항목 (See Also)

-   [[Plot_Tank_Results.m]] / [[Plot_Tank_Results.md]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`, `legend`, `hold`

# 전체 코드

```MATLAB
function Plot_Tank_m_t(ax, y)
%Plot_Tank_m_t Plots tank masses over time on the provided axes.
%   Plots y.tank.m, m_v, m_l against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed
plot(ax, y.time, y.tank.m, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Total (m)');
hold(ax, 'on');
plot(ax, y.time, y.tank.m_v, 'r--', 'DisplayName', 'Vapor (m_v)');
plot(ax, y.time, y.tank.m_l, 'k:', 'DisplayName', 'Liquid (m_l)'); % Liquid as dotted line
hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Mass (kg)');
title(ax, 'Tank Mass Components vs Time');
legend(ax, 'Location', 'best');

end 
``` 