---
tags:
  - 플롯
  - 탱크
  - 비열
  - 정적비열
  - cv
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Tank_Spec_cv_t.m` 문서

## 함수 개요

`Plot_Tank_Spec_cv_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 탱크 내 혼합물, 증기, 액체의 정적 비열(cv) 변화를 플롯합니다. 값은 자동으로 kJ/kg-K 단위로 변환됩니다.

```matlab
function Plot_Tank_Spec_cv_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.tank.cv`, `y.tank.cv_v`, `y.tank.cv_l` 필드 필요).
    -   `y.time` (단위: s)
    -   `y.tank.cv` (혼합물 cv, 단위: J/kg-K)
    -   `y.tank.cv_v` (증기 cv, 단위: J/kg-K)
    -   `y.tank.cv_l` (액체 cv, 단위: J/kg-K)

## 설명

`ax`로 지정된 `uiaxes` 객체에 정적 비열(`cv`, `cv_v`, `cv_l`)을 `y.time`에 대해 플롯합니다.

-   **플롯 스타일:**
    -   혼합물 `cv`: 파란색 실선 (`b-`), 선 굵기 1.5
    -   증기 `cv_v`: 빨간색 파선 (`r--`)
    -   액체 `cv_l`: 검정색 점선 (`k:`)
-   **단위 변환:** J/kg-K -> kJ/kg-K
-   **부가 기능:** 그리드 표시, 범례 표시, 축 레이블 및 제목 설정.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Tank_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabCv = uitab(tabGroup, 'Title', 'Specific Heat (cv)');
axCv = uiaxes(tabCv, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Tank_Spec_cv_t(axCv, y);
```

## 관련 항목 (See Also)

-   [[Plot_Tank_Results.m]] / [[Plot_Tank_Results.md]]
-   [[Plot_Tank_Spec_cp_t.m]] / [[Plot_Tank_Spec_cp_t.md]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`, `legend`, `hold`

# 전체 코드

```MATLAB
function Plot_Tank_Spec_cv_t(ax, y)
%Plot_Tank_Spec_cv_t Plots specific heat (cv) values on the provided axes.
%   Plots y.tank.cv, cv_v, cv_l (in kJ/kg-K) against y.time on axes ax.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure.

plot(ax, y.time, y.tank.cv / 1e3, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mixture (cv)'); % kJ/kg-K
hold(ax, 'on');
plot(ax, y.time, y.tank.cv_v / 1e3, 'r--', 'DisplayName', 'Vapor (cv_v)'); % kJ/kg-K
plot(ax, y.time, y.tank.cv_l / 1e3, 'k:', 'DisplayName', 'Liquid (cv_l)'); % kJ/kg-K, Liquid as dotted
hold(ax, 'off');
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Specific Heat cv (kJ/kg-K)');
title(ax, 'Tank Specific Heat (cv) vs Time');
legend(ax, 'Location', 'best');

end 