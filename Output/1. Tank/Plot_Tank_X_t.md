---
tags:
  - 플롯
  - 탱크
  - 건도
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Tank_X_t.m` 문서

## 함수 개요

`Plot_Tank_X_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 탱크 건도(vapor mass fraction) 변화를 플롯합니다.

```matlab
function Plot_Tank_X_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.tank.X` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.tank.X` (0~1 사이 값)

## 설명

`ax`로 지정된 `uiaxes` 객체에 탱크 건도 `y.tank.X`를 `y.time`에 대해 플롯합니다.

-   **플롯 스타일:** 녹색 실선 (`g-`), 선 굵기 1.5.
-   **부가 기능:** 그리드 표시, 축 레이블 및 제목 설정, y축 범위 `[0, 1.1]` 고정.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Tank_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabX = uitab(tabGroup, 'Title', 'Quality');
axX = uiaxes(tabX, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Tank_X_t(axX, y);
```

## 관련 항목 (See Also)

-   [[Plot_Tank_Results.m]] / [[Plot_Tank_Results.md]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`, `ylim`

# 전체 코드

```MATLAB
function Plot_Tank_X_t(ax, y)
%Plot_Tank_X_t Plots tank quality over time on the provided axes.
%   Plots y.tank.X against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

% figure; % Removed
plot(ax, y.time, y.tank.X, 'g-', 'LineWidth', 1.5);
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Quality (X)');
title(ax, 'Tank Quality vs Time');
ylim(ax, [0, 1.1]); % Ensure Y-axis includes 0 and 1 comfortably

end 