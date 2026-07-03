---
tags:
  - 플롯
  - 인젝터
  - 질량유량
  - NHNE
  - FML
  - mdot_inc
  - mdot_SPC
  - mdot_HEM
  - 시각화
lastmod: 2026-07-04
---
# `Plot_Inj_Mdot_Combined_t.m` 문서

## 함수 개요

`Plot_Inj_Mdot_Combined_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 총 인젝터 질량 유량(`mdot`)과, 사용한 모델의 질량 유량 성분(NHNE: `mdot_inc`/`mdot_HEM`, FML: `mdot_SPC`/`mdot_HEM`) 변화를 함께 플롯합니다.

```matlab
function Plot_Inj_Mdot_Combined_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.inj.mdot` 필수, 성분 필드는 선택).
    -   `y.time` (단위: s)
    -   `y.inj.mdot` (단위: kg/s) - 총 질량 유량
    -   `y.inj.mdot_inc` (단위: kg/s) - NHNE 비압축성 유량 성분 (Cd*A 포함)
    -   `y.inj.mdot_SPC` (단위: kg/s) - FML 단상 압축성 유량 성분 (Cd*A 포함)
    -   `y.inj.mdot_HEM` (단위: kg/s) - 균질 평형 유량 성분 (Cd*A 포함, 두 모델 공용)

## 설명

`ax`로 지정된 `uiaxes` 객체에 총 인젝터 질량 유량과 **Cd*A가 포함된** 모델 성분들을 `y.time`에 대해 함께 플롯합니다. **기록이 전부 NaN인 성분(해당 모델 미사용)은 자동으로 생략**되므로, NHNE 실행에서는 `mdot_inc`/`mdot_HEM`이, FML 실행에서는 `mdot_SPC`/`mdot_HEM`이 표시됩니다.

-   **플롯 스타일:**
    -   Total (`mdot`): 파란색 실선 (`b-`), 굵기 2.0
    -   NHNE (`mdot_inc`): 파란색 계열 점선 (`--`), 굵기 1.5
    -   FML (`mdot_SPC`): 초록색 계열 점선 (`--`), 굵기 1.5
    -   `mdot_HEM`: 빨간색 계열 점선 (`:`), 굵기 1.5
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
-   [[Inj_FML_LiqFeed.m]] / [[Inj_FML_LiqFeed.md]]
-   [[Inj_NHNE_VapFeed.m]] / [[Inj_NHNE_VapFeed.md]]
-   MATLAB 함수: `uiaxes`, `plot`, `hold`, `xlabel`, `ylabel`, `title`, `grid`, `legend`

# 전체 코드

```MATLAB
function Plot_Inj_Mdot_Combined_t(ax, y)
%Plot_Inj_Mdot_Combined_t Plots total and model component mass flow rates.
%   총 유량 y.inj.mdot과 함께, 사용한 인젝터 모델의 성분 유량을 표시한다.
%   - NHNE 모델: mdot_inc, mdot_HEM
%   - FML 모델:  mdot_SPC, mdot_HEM
%   기록이 전부 NaN인 성분(해당 모델 미사용)은 자동으로 생략된다.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.mdot;
%          component fields are optional and plotted only when data exists).

% 해당 필드에 유효한(NaN이 아닌) 기록이 하나라도 있는지 확인
has_data = @(f) isfield(y.inj, f) && any(~isnan(y.inj.(f)));

plot(ax, y.time, y.inj.mdot, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Total (mdot)');
hold(ax, 'on');
if has_data('mdot_inc')
    plot(ax, y.time, y.inj.mdot_inc, 'Color', [0 0.4470 0.7410], 'LineStyle', '--', 'LineWidth', 1.5, 'DisplayName', 'NHNE: mdot_{inc}');
end
if has_data('mdot_SPC')
    plot(ax, y.time, y.inj.mdot_SPC, 'Color', [0.4660 0.6740 0.1880], 'LineStyle', '--', 'LineWidth', 1.5, 'DisplayName', 'FML: mdot_{SPC}');
end
if has_data('mdot_HEM')
    plot(ax, y.time, y.inj.mdot_HEM, 'Color', [0.6350 0.0780 0.1840], 'LineStyle', ':', 'LineWidth', 1.5, 'DisplayName', 'mdot_{HEM}');
end
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Mass Flow Rate (kg/s)');
title(ax, 'Injector Mass Flow Rates (Total & Model Components) vs Time');
legend(ax, 'show', 'Location', 'best');

end
```
