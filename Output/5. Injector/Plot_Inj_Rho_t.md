---
tags:
  - 플롯
  - 인젝터
  - 밀도
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Inj_Rho_t.m` 문서

## 함수 개요

`Plot_Inj_Rho_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 인젝터 밀도(혼합물 `rho`, 기체상 `rho_v`, 액체상 `rho_l`, kg/m³) 변화를 함께 플롯합니다.

```matlab
function Plot_Inj_Rho_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.inj.rho`, `y.inj.rho_v`, `y.inj.rho_l` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.inj.rho` (단위: kg/m³)
    -   `y.inj.rho_v` (단위: kg/m³)
    -   `y.inj.rho_l` (단위: kg/m³)

## 설명

`ax`로 지정된 `uiaxes` 객체에 인젝터 혼합물, 기체상, 액체상 밀도를 `y.time`에 대해 함께 플롯합니다.

-   **플롯 스타일:**
    -   혼합물 (`rho`): 파란색 실선 (`b-`)
    -   기체상 (`rho_v`): 빨간색 점선 (`r--`)
    -   액체상 (`rho_l`): 검은색 점선 (`k--`)
    -   선 굵기: 1.5
-   **부가 기능:** 그리드 표시, 축 레이블, 제목 설정, 범례 표시.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Inj_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabRho = uitab(tabGroup, 'Title', 'Density');
axRho = uiaxes(tabRho, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Inj_Rho_t(axRho, y);
```

## 관련 항목 (See Also)

-   [[Plot_Inj_Results.m]] / [[Plot_Inj_Results.md]]
-   [[InjState_LiqFeed.m]]
-   [[InjState_VapFeed.m]]
-   MATLAB 함수: `uiaxes`, `plot`, `hold`, `xlabel`, `ylabel`, `title`, `grid`, `legend`

# 전체 코드

```MATLAB
function Plot_Inj_Rho_t(ax, y)
%Plot_Inj_Rho_t Plots injector densities (mixture, vapor, liquid) vs. time.
%   Plots y.inj.rho, rho_v, rho_l against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.rho, 
%          y.inj.rho_v, y.inj.rho_l).

plot(ax, y.time, y.inj.rho, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mixture (\rho)'); 
hold(ax, 'on');
plot(ax, y.time, y.inj.rho_v, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Vapor (\rho_v)');
plot(ax, y.time, y.inj.rho_l, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Liquid (\rho_l)');
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Density (kg/m^3)');
title(ax, 'Injector Density (Mixture, Vapor, Liquid) vs Time');
legend(ax, 'show', 'Location', 'best');

end 