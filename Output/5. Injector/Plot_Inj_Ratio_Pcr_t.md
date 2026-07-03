---
tags:
  - 플롯
  - 인젝터
  - 압력비
  - 임계압력비
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Inj_Ratio_Pcr_t.m` 문서

## 함수 개요

`Plot_Inj_Ratio_Pcr_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 인젝터 임계 압력비(`ratio_Pcr`) 변화를 플롯합니다.

```matlab
function Plot_Inj_Ratio_Pcr_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.inj.ratio_Pcr` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.inj.ratio_Pcr` (무차원)

## 설명

`ax`로 지정된 `uiaxes` 객체에 인젝터 임계 압력비 `y.inj.ratio_Pcr`를 `y.time`에 대해 플롯합니다.

-   **플롯 스타일:** 자홍색 점선 (`m-.`), 선 굵기 1.5.
-   **부가 기능:** 그리드 표시, 축 레이블 및 제목 설정.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Inj_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabPcr = uitab(tabGroup, 'Title', 'Crit. Pressure Ratio');
axPcr = uiaxes(tabPcr, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Inj_Ratio_Pcr_t(axPcr, y);
```

## 관련 항목 (See Also)

-   [[Plot_Inj_Results.m]] / [[Plot_Inj_Results.md]]
-   [[Plot_Inj_Ratio_P_t.m]] / [[Plot_Inj_Ratio_P_t.md]]
-   [[Inj_ICF_VapFeed.m]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`

# 전체 코드

```MATLAB
function Plot_Inj_Ratio_Pcr_t(ax, y)
%Plot_Inj_Ratio_Pcr_t Plots the injector critical pressure ratio vs. time.
%   Plots y.inj.ratio_Pcr against y.time on the provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.ratio_Pcr).

plot(ax, y.time, y.inj.ratio_Pcr, 'm-.', 'LineWidth', 1.5); % Magenta dash-dot line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Critical Pressure Ratio (-)');
title(ax, 'Injector Critical Pressure Ratio (P_{cr}/P_{inj}) vs Time');

end 