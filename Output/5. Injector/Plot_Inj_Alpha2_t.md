---
tags:
  - 플롯
  - 인젝터
  - FML
  - 보이드율
  - 시각화
lastmod: 2026-07-04
---
# `Plot_Inj_Alpha2_t.m` 문서

## 함수 개요

`Plot_Inj_Alpha2_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 FML 모델의 하류 보이드율 `alpha2`와 초킹 여부 `choked`를 플롯합니다.

```matlab
function Plot_Inj_Alpha2_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체 (`y.time`, `y.inj.alpha2` 필드 필요, `y.inj.choked`는 선택).
    -   `y.time` (단위: s)
    -   `y.inj.alpha2` (무차원, 0~1) — FML 질량 유량 가중치 (논문 식 (24))
    -   `y.inj.choked` (0/1) — SPC/HEM 공통 임계 압력비 기준 초킹 여부

## 설명

`ax`로 지정된 `uiaxes` 객체에 왼쪽 축으로 보이드율 $\alpha_2$, 오른쪽 축으로 초킹 플래그를 플롯합니다. $\alpha_2 \to 1$이면 하류가 대부분 증기(액상 유출 시 HEM 지배), $\alpha_2 \to 0$이면 대부분 액체(SPC 지배)를 의미하므로 FML 가중 거동 검증에 사용합니다.

-   **플롯 스타일:** 왼쪽 축 보라색 실선($\alpha_2$), 오른쪽 축 주황색 계단형 점선(choked).
-   **표시 조건:** NHNE/CdA 모델 실행에서는 `alpha2` 기록이 전부 NaN이므로 `Plot_Inj_Results`에서 이 탭 자체가 생략됩니다.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Inj_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
if has_data('alpha2')
    tabAlpha2 = uitab(tabGroup, 'Title', 'Void Fraction (FML)');
    axAlpha2 = uiaxes(tabAlpha2, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
    Plot_Inj_Alpha2_t(axAlpha2, y);
end
```

## 관련 항목 (See Also)

-   [[Plot_Inj_Results.m]] / [[Plot_Inj_Results.md]]
-   [[Inj_FML_LiqFeed.m]] / [[Inj_FML_LiqFeed.md]]
-   [[Inj_NHNE_VapFeed.m]] / [[Inj_NHNE_VapFeed.md]]
-   MATLAB 함수: `uiaxes`, `plot`, `stairs`, `yyaxis`, `xlabel`, `ylabel`, `title`, `grid`

# 전체 코드

```MATLAB
function Plot_Inj_Alpha2_t(ax, y)
%Plot_Inj_Alpha2_t Plots the FML downstream void fraction and choking flag vs. time.
%   왼쪽 축: 하류 보이드율 alpha2 (FML 가중치, 0~1)
%   오른쪽 축: 초킹 여부 choked (0/1)
%   NHNE/CdA 모델 실행에서는 값이 없어(전부 NaN) Plot_Inj_Results에서
%   이 탭 자체가 생략된다.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.alpha2;
%          y.inj.choked is optional).

yyaxis(ax, 'left');
plot(ax, y.time, y.inj.alpha2, 'Color', [0.4940 0.1840 0.5560], 'LineStyle', '-', 'LineWidth', 1.8);
ylabel(ax, 'Void Fraction \alpha_2 (-)');
ylim(ax, [-0.05, 1.05]);

if isfield(y.inj, 'choked') && any(~isnan(y.inj.choked))
    yyaxis(ax, 'right');
    stairs(ax, y.time, double(y.inj.choked), 'Color', [0.8500 0.3250 0.0980], 'LineStyle', '--', 'LineWidth', 1.2);
    ylabel(ax, 'Choked (0/1)');
    ylim(ax, [-0.05, 1.05]);
end

grid(ax, 'on');
xlabel(ax, 'Time (s)');
title(ax, 'FML Void Fraction (\alpha_2) & Choking Flag vs Time');

end
```
