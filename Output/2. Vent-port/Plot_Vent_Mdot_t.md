---
tags:
  - 플롯
  - 벤트포트
  - 질량유량
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Vent_Mdot_t.m` 문서

## 함수 개요

`Plot_Vent_Mdot_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 벤트 포트를 통과하는 질량 유량(`mdot`, kg/s)의 변화를 플롯합니다.

```matlab
function Plot_Vent_Mdot_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.vent.mdot` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.vent.mdot` (단위: kg/s)

## 설명

`ax`로 지정된 `uiaxes` 객체에 질량 유량 `y.vent.mdot`을 `y.time`에 대해 플롯합니다.

-   **플롯 스타일:** 검은색 실선 (`k-`), 선 굵기 1.5.
-   **부가 기능:** 그리드 표시, 축 레이블 및 제목 설정.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Vent_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabMdot = uitab(tabGroup, 'Title', 'Mass Flow Rate');
axMdot = uiaxes(tabMdot, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Vent_Mdot_t(axMdot, y);
```

## 관련 항목 (See Also)

-   [[Plot_Vent_Results.m]] / [[Plot_Vent_Results.md]]
-   [[Plot_Vent_Ratio_Pcr_t.m]] / [[Plot_Vent_Ratio_Pcr_t.md]]
-   [[Plot_Vent_Ratio_P_t.m]] / [[Plot_Vent_Ratio_P_t.md]]
-   [[Vent_ICF.m]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`

# 전체 코드

```MATLAB
function Plot_Vent_Mdot_t(ax, y)
%Plot_Vent_Mdot_t Plots the mass flow rate through the vent port.
%   Plots y.vent.mdot (in kg/s) against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.vent.mdot).

plot(ax, y.time, y.vent.mdot, 'k-', 'LineWidth', 1.5); % Black solid line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Vent Mass Flow Rate (kg/s)');
title(ax, 'Vent Mass Flow Rate vs Time');

end 