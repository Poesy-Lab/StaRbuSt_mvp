---
tags:
  - 플롯
  - 인젝터
  - kappa
  - NHNE
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Inj_Kappa_t.m` 문서

## 함수 개요

`Plot_Inj_Kappa_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 인젝터 NHNE 모델 파라미터 `kappa` 변화를 플롯합니다.

```matlab
function Plot_Inj_Kappa_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.inj.kappa` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.inj.kappa` (무차원)

## 설명

`ax`로 지정된 `uiaxes` 객체에 인젝터 `kappa` 값을 `y.time`에 대해 플롯합니다. 이 값은 주로 액상 공급(LiqFeed) 단계에서 계산되며, 기상 공급(VapFeed) 단계에서는 NaN일 수 있습니다.

-   **플롯 스타일:** 하늘색 점선 (`[0.3010 0.7450 0.9330]`, `--`), 선 굵기 1.5.
-   **부가 기능:** 그리드 표시, 축 레이블 및 제목 설정.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Inj_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabKappa = uitab(tabGroup, 'Title', 'Kappa (NHNE)');
axKappa = uiaxes(tabKappa, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Inj_Kappa_t(axKappa, y);
```

## 관련 항목 (See Also)

-   [[Plot_Inj_Results.m]] / [[Plot_Inj_Results.md]]
-   [[Inj_NHNE_LiqFeed.m]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`

# 전체 코드

```MATLAB
function Plot_Inj_Kappa_t(ax, y)
%Plot_Inj_Kappa_t Plots the injector NHNE model parameter kappa vs. time.
%   Plots y.inj.kappa against y.time on the provided axes ax.
%   This value is typically NaN during VapFeed.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.kappa).

plot(ax, y.time, y.inj.kappa, 'Color', [0.3010 0.7450 0.9330], 'LineStyle', '--', 'LineWidth', 1.5); % Light blue dashed line
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Kappa (NHNE) (-)');
title(ax, 'Injector NHNE Model Parameter (Kappa) vs Time');

end 