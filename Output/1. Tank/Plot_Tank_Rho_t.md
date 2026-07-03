---
tags:
  - 플롯
  - 탱크
  - 밀도
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Tank_Rho_t.m` 문서

## 함수 개요

`Plot_Tank_Rho_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 탱크 내 혼합물, 증기, 액체 밀도 변화(kg/m³)를 플롯합니다.

```matlab
function Plot_Tank_Rho_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.tank.rho`, `y.tank.rho_v`, `y.tank.rho_l` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.tank.rho` (혼합물 밀도, 단위: kg/m³)
    -   `y.tank.rho_v` (증기 밀도, 단위: kg/m³)
    -   `y.tank.rho_l` (액체 밀도, 단위: kg/m³)

## 설명

`ax`로 지정된 `uiaxes` 객체에 혼합물 밀도(`rho`), 증기 밀도(`rho_v`), 액체 밀도(`rho_l`)를 `y.time`에 대해 플롯합니다.

-   **플롯 스타일:**
    -   혼합물 밀도: 파란색 실선 (`b-`), 선 굵기 1.5
    -   증기 밀도: 빨간색 파선 (`r--`)
    -   액체 밀도: 검정색 점선 (`k:`)
-   **부가 기능:** 그리드 표시, 범례 표시, 축 레이블 및 제목 설정.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Tank_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabRho = uitab(tabGroup, 'Title', 'Density');
axRho = uiaxes(tabRho, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Tank_Rho_t(axRho, y);
```

## 관련 항목 (See Also)

-   [[Plot_Tank_Results.m]] / [[Plot_Tank_Results.md]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`, `legend`, `hold`

# 전체 코드

```MATLAB
function Plot_Tank_Rho_t(ax, y)
%Plot_Tank_Rho_t Plots tank densities over time on the provided axes.
%   Plots y.tank.rho, rho_v, rho_l against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed
plot(ax, y.time, y.tank.rho, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mixture (rho)');
hold(ax, 'on');
plot(ax, y.time, y.tank.rho_v, 'r--', 'DisplayName', 'Vapor (rho_v)');
plot(ax, y.time, y.tank.rho_l, 'k:', 'DisplayName', 'Liquid (rho_l)'); % Liquid as dotted line
hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Density (kg/m^3)');
title(ax, 'Tank Densities vs Time');
legend(ax, 'Location', 'best');

end 