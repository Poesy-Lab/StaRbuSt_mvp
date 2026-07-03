---
tags:
  - 플롯
  - 인젝터
  - 비엔트로피
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Inj_Spec_s_t.m` 문서

## 함수 개요

`Plot_Inj_Spec_s_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 인젝터 비엔트로피(혼합물 `s`, 기체상 `s_v`, 액체상 `s_l`, kJ/kg-K) 변화를 함께 플롯합니다. 입력된 값(J/kg-K)을 kJ/kg-K 단위로 변환하여 표시합니다.

```matlab
function Plot_Inj_Spec_s_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.inj.s`, `y.inj.s_v`, `y.inj.s_l` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.inj.s` (단위: J/kg-K)
    -   `y.inj.s_v` (단위: J/kg-K)
    -   `y.inj.s_l` (단위: J/kg-K)

## 설명

`ax`로 지정된 `uiaxes` 객체에 인젝터 혼합물, 기체상, 액체상 비엔트로피 (J/kg-K)를 kJ/kg-K로 변환하여 `y.time`에 대해 함께 플롯합니다.

-   **단위 변환:** `_kJ = y.inj._ / 1000`
-   **플롯 스타일:**
    -   혼합물 (`s`): 파란색 실선 (`b-`)
    -   기체상 (`s_v`): 빨간색 점선 (`r--`)
    -   액체상 (`s_l`): 검은색 점선 (`k--`)
    -   선 굵기: 1.5
-   **부가 기능:** 그리드 표시, 축 레이블 (kJ/kg-K 단위 명시), 제목 설정, 범례 표시.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Inj_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabS = uitab(tabGroup, 'Title', 'Specific Entropy');
axS = uiaxes(tabS, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Inj_Spec_s_t(axS, y);
```

## 관련 항목 (See Also)

-   [[Plot_Inj_Results.m]] / [[Plot_Inj_Results.md]]
-   [[InjState_LiqFeed.m]]
-   [[InjState_VapFeed.m]]
-   MATLAB 함수: `uiaxes`, `plot`, `hold`, `xlabel`, `ylabel`, `title`, `grid`, `legend`

# 전체 코드

```MATLAB
function Plot_Inj_Spec_s_t(ax, y)
%Plot_Inj_Spec_s_t Plots injector spec. entropy (mix, vap, liq) vs. time.
%   Plots y.inj.s, s_v, s_l (converted to kJ/kg-K) against y.time on the
%   provided axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.s, 
%          y.inj.s_v, y.inj.s_l in J/kg-K).

s_kJ   = y.inj.s / 1000;   % Convert J/kg-K to kJ/kg-K
s_v_kJ = y.inj.s_v / 1000; % Convert J/kg-K to kJ/kg-K
s_l_kJ = y.inj.s_l / 1000; % Convert J/kg-K to kJ/kg-K

plot(ax, y.time, s_kJ,   'b-',  'LineWidth', 1.5, 'DisplayName', 'Mixture (s)'); 
hold(ax, 'on');
plot(ax, y.time, s_v_kJ, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Vapor (s_v)');
plot(ax, y.time, s_l_kJ, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Liquid (s_l)');
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Injector Spec. Entropy (kJ/kg-K)');
title(ax, 'Injector Specific Entropy (Mixture, Vapor, Liquid) vs Time');
legend(ax, 'show', 'Location', 'best');

end
``` 