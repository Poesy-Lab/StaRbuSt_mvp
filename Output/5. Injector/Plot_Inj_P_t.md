---
tags:
  - 플롯
  - 인젝터
  - 압력
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Inj_P_t.m` 문서

## 함수 개요

`Plot_Inj_P_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 인젝터 압력(`P`, bar) 변화를 플롯합니다. 입력된 압력값(Pa)을 bar 단위로 변환하여 표시합니다.

```matlab
function Plot_Inj_P_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.inj.P` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.inj.P` (단위: Pa)

## 설명

`ax`로 지정된 `uiaxes` 객체에 인젝터 압력 `y.inj.P` (Pa)를 bar로 변환하여 `y.time`에 대해 플롯합니다.

-   **단위 변환:** `P_bar = y.inj.P / 1e5`
-   **플롯 스타일:** 빨간색 실선 (`r-`), 선 굵기 1.5.
-   **부가 기능:** 그리드 표시, 축 레이블 (bar 단위 명시) 및 제목 설정.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Inj_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabP = uitab(tabGroup, 'Title', 'Pressure');
axP = uiaxes(tabP, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Inj_P_t(axP, y);
```

## 관련 항목 (See Also)

-   [[Plot_Inj_Results.m]] / [[Plot_Inj_Results.md]]
-   [[Plot_Inj_Mdot_t.m]] / [[Plot_Inj_Mdot_t.md]]
-   [[Plot_Inj_T_t.m]] / [[Plot_Inj_T_t.md]]
-   [[InjState_LiqFeed.m]]
-   [[InjState_VapFeed.m]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`

# 전체 코드

```MATLAB
function Plot_Inj_P_t(ax, y)
%Plot_Inj_P_t Plots the injector pressure vs. time.
%   Plots y.inj.P (converted from Pa to bar) against y.time on the 
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.P in Pa).

P_bar = y.inj.P / 1e5; % Convert Pa to bar

plot(ax, y.time, P_bar, 'r-', 'LineWidth', 1.5); % Red solid line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Pressure (bar)');
title(ax, 'Injector Pressure vs Time');

end 