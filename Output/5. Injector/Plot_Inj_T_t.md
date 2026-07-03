---
tags:
  - 플롯
  - 인젝터
  - 온도
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Inj_T_t.m` 문서

## 함수 개요

`Plot_Inj_T_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 인젝터 온도(`T`, °C) 변화를 플롯합니다. 입력된 온도값(K)을 섭씨(°C) 단위로 변환하여 표시합니다.

```matlab
function Plot_Inj_T_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.inj.T` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.inj.T` (단위: K)

## 설명

`ax`로 지정된 `uiaxes` 객체에 인젝터 온도 `y.inj.T` (K)를 섭씨(°C)로 변환하여 `y.time`에 대해 플롯합니다.

-   **단위 변환:** `T_C = y.inj.T - 273.15`
-   **플롯 스타일:** 녹색 실선 (`g-`), 선 굵기 1.5.
-   **부가 기능:** 그리드 표시, 축 레이블 (°C 단위 명시) 및 제목 설정.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Inj_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabT = uitab(tabGroup, 'Title', 'Temperature');
axT = uiaxes(tabT, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Inj_T_t(axT, y);
```

## 관련 항목 (See Also)

-   [[Plot_Inj_Results.m]] / [[Plot_Inj_Results.md]]
-   [[Plot_Inj_Mdot_t.m]] / [[Plot_Inj_Mdot_t.md]]
-   [[Plot_Inj_P_t.m]] / [[Plot_Inj_P_t.md]]
-   [[InjState_LiqFeed.m]]
-   [[InjState_VapFeed.m]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`

# 전체 코드

```MATLAB
function Plot_Inj_T_t(ax, y)
%Plot_Inj_T_t Plots the injector temperature vs. time.
%   Plots y.inj.T (converted from K to C) against y.time on the 
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.T in K).

T_C = y.inj.T - 273.15; % Convert K to Celsius

plot(ax, y.time, T_C, 'g-', 'LineWidth', 1.5); % Green solid line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Temperature (°C)');
title(ax, 'Injector Temperature vs Time');

end 