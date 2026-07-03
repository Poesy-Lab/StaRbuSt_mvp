---
tags:
  - 플롯
  - 벤트포트
  - 결과 시각화
  - 메인 플롯
lastmod: 2025-04-30
---
# `Plot_Vent_Results.m` 문서

## 함수 개요

`Plot_Vent_Results` 함수는 벤트 포트 시뮬레이션 결과(`ratio_Pcr`, `ratio_P`, `mdot`)를 시각화하는 메인 함수입니다. 새로운 `uifigure` 창을 생성하고, 각 결과 항목에 대한 탭을 만들어 해당 탭에 개별 플로팅 함수를 호출하여 그래프를 표시합니다.

```matlab
function fig = Plot_Vent_Results(t, y)
```

## 입력값

-   `t`: (N x 1 double) 시뮬레이션 시간 배열 (초).
-   `y`: (struct) 시뮬레이션 결과 상태 변수를 포함하는 구조체. `y.vent` 하위 구조체 (`ratio_Pcr`, `ratio_P`, `mdot` 필드 포함)를 사용합니다.

## 출력값

-   `fig`: 생성된 `uifigure` 핸들.

## 설명

1.  **기존 창 닫기:** 함수 실행 시 'Vent Port Simulation Results'라는 이름의 기존 `uifigure` 창이 있으면 자동으로 닫습니다.
2.  **새 Figure 생성:** 'Vent Port Simulation Results'라는 이름으로 새로운 `uifigure` 창을 생성합니다.
3.  **탭 그룹 생성:** Figure 내부에 `uitabgroup`을 생성하여 플롯들을 탭으로 구성합니다.
4.  **개별 플롯 생성 (탭):**
    *   **Critical Pressure Ratio 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Vent_Ratio_Pcr_t.m]]` 함수를 호출하여 `ratio_Pcr` 대 시간 그래프를 플롯합니다.
    *   **Pressure Ratio (Pamb/Ptank) 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Vent_Ratio_P_t.m]]` 함수를 호출하여 `ratio_P` 대 시간 그래프를 플롯합니다.
    *   **Mass Flow Rate 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Vent_Mdot_t.m]]` 함수를 호출하여 `mdot` 대 시간 그래프를 플롯합니다.
5.  **Figure 핸들 반환:** 생성된 `uifigure`의 핸들을 반환합니다.

## 사용 예시 (`Test_StaRbuSt.m` 등에서)

```matlab
% 가정: t와 y 구조체가 이미 정의되어 있음
vent_fig_handle = Plot_Vent_Results(t, y);
```

## 관련 항목 (See Also)

-   [[Plot_Vent_Ratio_Pcr_t.m]] / [[Plot_Vent_Ratio_Pcr_t.md]]
-   [[Plot_Vent_Ratio_P_t.m]] / [[Plot_Vent_Ratio_P_t.md]]
-   [[Plot_Vent_Mdot_t.m]] / [[Plot_Vent_Mdot_t.md]]
-   [[Vent_ICF.m]]
-   MATLAB 함수: `uifigure`, `uitabgroup`, `uitab`, `uiaxes`, `findall`, `close`, `fprintf`, `struct`

# 전체 코드

```MATLAB
function fig = Plot_Vent_Results(t, y)
% Plot_Vent_Results Creates a figure with tabs for vent port simulation results.
%
% Args:
%   t (double): Time vector (s).
%   y (struct): Simulation results structure containing y.vent data.
%
% Returns:
%   fig (figure): Handle to the created figure.

% Check if a figure with the same name already exists and close it
fig_name = 'Vent Port Simulation Results';
existing_figs = findall(0, 'Type', 'figure', 'Name', fig_name);
if ~isempty(existing_figs)
    fprintf('Closing existing figure: ''%s''\n', fig_name);
    close(existing_figs);
end

% Create a new figure
fig = uifigure('Name', fig_name, 'Position', [200, 200, 700, 500]);

% Create a TabGroup
tabGroup = uitabgroup(fig, 'Position', [20, 20, 660, 460]);

% -- Tab 1: Critical Pressure Ratio --
tabPcr = uitab(tabGroup, 'Title', 'Critical Pressure Ratio');
axPcr = uiaxes(tabPcr, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Vent_Ratio_Pcr_t(axPcr, struct('time', t, 'vent', y.vent)); % Pass t explicitly as y.time

% -- Tab 2: Pressure Ratio (Pamb/Ptank) --
tabP = uitab(tabGroup, 'Title', 'Pressure Ratio (Pamb/Ptank)');
axP = uiaxes(tabP, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Vent_Ratio_P_t(axP, struct('time', t, 'vent', y.vent)); % Pass t explicitly as y.time

% -- Tab 3: Mass Flow Rate --
tabMdot = uitab(tabGroup, 'Title', 'Mass Flow Rate');
axMdot = uiaxes(tabMdot, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Vent_Mdot_t(axMdot, struct('time', t, 'vent', y.vent)); % Pass t explicitly as y.time

end 