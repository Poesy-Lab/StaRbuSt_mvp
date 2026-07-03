---
tags:
  - 플롯
  - 탱크
  - 엔탈피
  - 총엔탈피
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Tank_Total_H_t.m` 문서

## 함수 개요

`Plot_Tank_Total_H_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 탱크 내 총 엔탈피(H) 변화를 플롯합니다. 값은 자동으로 MJ 단위로 변환됩니다.

```matlab
function Plot_Tank_Total_H_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.tank.H` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.tank.H` (총 엔탈피, 단위: J)

## 설명

`ax`로 지정된 `uiaxes` 객체에 총 엔탈피 `y.tank.H`를 `y.time`에 대해 플롯합니다.

-   **플롯 스타일:** 파란색 실선 (`b-`), 선 굵기 1.5.
-   **단위 변환:** J -> MJ
-   **부가 기능:** 그리드 표시, 범례 표시, 축 레이블 및 제목 설정.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.
-   **참고:** 현재 총 엔탈피만 플롯합니다. (증기/액체 성분 플롯 기능은 코드 내 주석 처리됨)

## 사용 예시 (`Plot_Tank_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabTotalH = uitab(tabGroup, 'Title', 'Total Enthalpy');
axTotalH = uiaxes(tabTotalH, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Tank_Total_H_t(axTotalH, y);
```

## 관련 항목 (See Also)

-   [[Plot_Tank_Results.m]] / [[Plot_Tank_Results.md]]
-   [[Plot_Tank_Total_S_t.m]] / [[Plot_Tank_Total_S_t.md]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`, `legend`

# 전체 코드

```MATLAB
function Plot_Tank_Total_H_t(ax, y)
%Plot_Tank_Total_H_t Plots total enthalpy on the provided axes.
%   Plots y.tank.H (in MJ) against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

plot(ax, y.time, y.tank.H / 1e6, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Total (H)'); % MJ
% hold(ax, 'on');
% % Add H_v, H_l plotting here if they become available in y.tank
% hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Total Enthalpy (MJ)');
title(ax, 'Tank Total Enthalpy vs Time');
legend(ax, 'Location', 'best');

end 