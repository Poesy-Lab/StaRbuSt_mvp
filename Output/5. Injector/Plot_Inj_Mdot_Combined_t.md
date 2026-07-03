---
tags:
  - 플롯
  - 인젝터
  - 질량유량
  - NHNE
  - mdot_inc
  - mdot_HEM
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Inj_Mdot_Combined_t.m` 문서

## 함수 개요

`Plot_Inj_Mdot_Combined_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 총 인젝터 질량 유량(`mdot`)과 NHNE 모델의 질량 유량 성분(`mdot_inc`, `mdot_HEM`) 변화를 함께 플롯합니다.

```matlab
function Plot_Inj_Mdot_Combined_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.inj.mdot`, `y.inj.mdot_inc`, `y.inj.mdot_HEM` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.inj.mdot` (단위: kg/s) - 총 질량 유량
    -   `y.inj.mdot_inc` (단위: kg/s) - NHNE 비압축성 유량 성분 (Cd*A 포함)
    -   `y.inj.mdot_HEM` (단위: kg/s) - NHNE 균질 평형 유량 성분 (Cd*A 포함)

## 설명

`ax`로 지정된 `uiaxes` 객체에 총 인젝터 질량 유량과 **Cd*A가 포함된** NHNE 성분들을 `y.time`에 대해 함께 플롯합니다. NHNE 성분들은 주로 액상 공급(LiqFeed) 단계에서 계산되며, 기상 공급(VapFeed) 단계에서는 NaN일 수 있습니다.

-   **플롯 스타일:**
    -   Total (`mdot`): 파란색 실선 (`b-`), 굵기 2.0
    -   NHNE (`mdot_inc`): 파란색 계열 점선 (`--`), 굵기 1.5
    -   NHNE (`mdot_HEM`): 빨간색 계열 점선 (`:`), 굵기 1.5
-   **부가 기능:** 그리드 표시, 축 레이블, 제목 설정, 범례 표시.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Inj_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabMdotComb = uitab(tabGroup, 'Title', 'Mass Flow Rates (Total & NHNE)');
axMdotComb = uiaxes(tabMdotComb, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Inj_Mdot_Combined_t(axMdotComb, y);
```

## 관련 항목 (See Also)

-   [[Plot_Inj_Results.m]] / [[Plot_Inj_Results.md]]
-   [[Inj_NHNE_LiqFeed.m]]
-   MATLAB 함수: `uiaxes`, `plot`, `hold`, `xlabel`, `ylabel`, `title`, `grid`, `legend`

# 전체 코드

```MATLAB
function Plot_Inj_Mdot_Combined_t(ax, y)
%Plot_Inj_Mdot_Combined_t Plots total and NHNE component mass flow rates.
%   Plots y.inj.mdot (total), y.inj.mdot_inc (inc. Cd*A), and y.inj.mdot_HEM (inc. Cd*A)
%   against y.time on the provided axes ax.
%   NHNE components might be NaN during VapFeed.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.mdot, 
%          y.inj.mdot_inc (with Cd*A), y.inj.mdot_HEM (with Cd*A)).

plot(ax, y.time, y.inj.mdot,       'b-',  'LineWidth', 2.0, 'DisplayName', 'Total (mdot)');
hold(ax, 'on');
plot(ax, y.time, y.inj.mdot_inc, 'Color', [0 0.4470 0.7410], 'LineStyle', '--', 'LineWidth', 1.5, 'DisplayName', 'NHNE: mdot_{inc}');
plot(ax, y.time, y.inj.mdot_HEM, 'Color', [0.6350 0.0780 0.1840], 'LineStyle', ':', 'LineWidth', 1.5, 'DisplayName', 'NHNE: mdot_{HEM}');
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Mass Flow Rate (kg/s)');
title(ax, 'Injector Mass Flow Rates (Total & NHNE Components) vs Time');
legend(ax, 'show', 'Location', 'best');

end 