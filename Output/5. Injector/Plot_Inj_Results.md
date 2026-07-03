---
tags:
  - 플롯
  - 인젝터
  - 결과 시각화
  - 메인 플롯
lastmod: 2025-04-30
---
# `Plot_Inj_Results.m` 문서

## 함수 개요

`Plot_Inj_Results` 함수는 인젝터 시뮬레이션 결과(`mdot`, `P`, `T` 등)를 시각화하는 메인 함수입니다. 새로운 `uifigure` 창을 생성하고, 각 결과 항목에 대한 탭을 만들어 해당 탭에 개별 플로팅 함수를 호출하여 그래프를 표시합니다.

```matlab
function fig = Plot_Inj_Results(y)
```

## 입력값

-   `y`: (struct) 시뮬레이션 결과 구조체. `y.time` 및 `y.inj` 하위 구조체 (`mdot`, `P`, `T` 등 필드 포함)를 사용합니다.

## 출력값

-   `fig`: 생성된 `uifigure` 핸들.

## 설명

1.  **기존 창 닫기:** 함수 실행 시 'Injector Simulation Results'라는 이름의 기존 `uifigure` 창이 있으면 자동으로 닫습니다.
2.  **새 Figure 생성:** 'Injector Simulation Results'라는 이름으로 새로운 `uifigure` 창을 생성합니다.
3.  **탭 그룹 생성:** Figure 내부에 `uitabgroup`을 생성하여 플롯들을 탭으로 구성합니다.
4.  **개별 플롯 생성 (탭):**
    *   **Mass Flow Rates (Total & NHNE) 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_Mdot_Combined_t.m]]` 함수를 호출하여 `mdot`, `mdot_inc`, `mdot_HEM` 대 시간 그래프를 플롯합니다. (통합됨)
    *   **Pressure 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_P_t.m]]` 함수를 호출하여 `P` (bar) 대 시간 그래프를 플롯합니다.
    *   **Temperature 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_T_t.m]]` 함수를 호출하여 `T` (°C) 대 시간 그래프를 플롯합니다.
    *   **State 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_State_t.m]]` 함수를 호출하여 `state` 대 시간 그래프를 플롯합니다.
    *   **Quality 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_X_t.m]]` 함수를 호출하여 `X` 대 시간 그래프를 플롯합니다.
    *   **Density 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_Rho_t.m]]` 함수를 호출하여 `rho` 대 시간 그래프를 플롯합니다.
    *   **Specific Internal Energy 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_Spec_u_t.m]]` 함수를 호출하여 `u` (kJ/kg) 대 시간 그래프를 플롯합니다.
    *   **Specific Entropy 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_Spec_s_t.m]]` 함수를 호출하여 `s` (kJ/kg-K) 대 시간 그래프를 플롯합니다.
    *   **Specific Enthalpy 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_Spec_h_t.m]]` 함수를 호출하여 `h` (kJ/kg) 대 시간 그래프를 플롯합니다.
    *   **Specific Heat (cp) 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_Spec_cp_t.m]]` 함수를 호출하여 `cp` (kJ/kg-K) 대 시간 그래프를 플롯합니다.
    *   **Specific Heat (cv) 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_Spec_cv_t.m]]` 함수를 호출하여 `cv` (kJ/kg-K) 대 시간 그래프를 플롯합니다.
    *   **Critical Pressure Ratio 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_Ratio_Pcr_t.m]]` 함수를 호출하여 `ratio_Pcr` 대 시간 그래프를 플롯합니다.
    *   **Pressure Ratio 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_Ratio_P_t.m]]` 함수를 호출하여 `ratio_P` 대 시간 그래프를 플롯합니다.
    *   **Kappa (NHNE) 탭:** `uitab`과 `uiaxes`를 생성하고 `[[Plot_Inj_Kappa_t.m]]` 함수를 호출하여 `kappa` 대 시간 그래프를 플롯합니다.
    *   **NHNE Mdot Components 탭:** (제거됨 - Mass Flow Rates 탭으로 통합)
5.  **Figure 핸들 반환:** 생성된 `uifigure`의 핸들을 반환합니다.

## 사용 예시 (`PlotResults.m` 내)

```matlab
% 가정: y 구조체가 이미 정의되어 있음
inj_fig_handle = Plot_Inj_Results(y);
```

## 관련 항목 (See Also)

-   [[Plot_Inj_Mdot_Combined_t.m]] / [[Plot_Inj_Mdot_Combined_t.md]] % 통합됨
-   [[Plot_Inj_P_t.m]] / [[Plot_Inj_P_t.md]]
-   [[Plot_Inj_T_t.m]] / [[Plot_Inj_T_t.md]]
-   [[Plot_Inj_State_t.m]] / [[Plot_Inj_State_t.md]]
-   [[Plot_Inj_X_t.m]] / [[Plot_Inj_X_t.md]]
-   [[Plot_Inj_Rho_t.m]] / [[Plot_Inj_Rho_t.md]]
-   [[Plot_Inj_Spec_u_t.m]] / [[Plot_Inj_Spec_u_t.md]]
-   [[Plot_Inj_Spec_s_t.m]] / [[Plot_Inj_Spec_s_t.md]]
-   [[Plot_Inj_Spec_h_t.m]] / [[Plot_Inj_Spec_h_t.md]]
-   [[Plot_Inj_Spec_cp_t.m]] / [[Plot_Inj_Spec_cp_t.md]]
-   [[Plot_Inj_Spec_cv_t.m]] / [[Plot_Inj_Spec_cv_t.md]]
-   [[Plot_Inj_Ratio_Pcr_t.m]] / [[Plot_Inj_Ratio_Pcr_t.md]]
-   [[Plot_Inj_Ratio_P_t.m]] / [[Plot_Inj_Ratio_P_t.md]]
-   [[Plot_Inj_Kappa_t.m]] / [[Plot_Inj_Kappa_t.md]]
-   [[Plot_Inj_Mdot_NHNE_t.m]] / [[Plot_Inj_Mdot_NHNE_t.md]] % 제거됨
-   [[PlotResults.m]]
-   MATLAB 함수: `uifigure`, `uitabgroup`, `uitab`, `uiaxes`, `findall`, `close`, `fprintf`, `try`, `catch`, `warning`, `stairs`, `ylim`, `hold`, `legend`

# 전체 코드

```MATLAB
function fig = Plot_Inj_Results(y)
% Plot_Inj_Results Creates a figure with tabs for injector simulation results.
%
% Args:
%   y (struct): Simulation results structure containing y.time and y.inj data.
%
% Returns:
%   fig (figure): Handle to the created figure.

% Check if a figure with the same name already exists and close it
fig_name = 'Injector Simulation Results';
existing_figs = findall(0, 'Type', 'figure', 'Name', fig_name);
if ~isempty(existing_figs)
    fprintf('Closing existing figure: ''%s''\n', fig_name);
    close(existing_figs);
end

% Create a new figure
fig = uifigure('Name', fig_name, 'Position', [300, 150, 700, 500]); % Adjusted position

% Create a TabGroup
tabGroup = uitabgroup(fig, 'Position', [20, 20, 660, 460]);

% Define axes position
axesPosition = [0.07, 0.12, 0.88, 0.8];

% -- Tab 1: Mass Flow Rates (Total & NHNE) -- % Combined Mdot
try
    tabMdotComb = uitab(tabGroup, 'Title', 'Mass Flow Rates (Total & NHNE)');
    axMdotComb = uiaxes(tabMdotComb, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Mdot_Combined_t(axMdotComb, y); % Call combined function
catch ME
    warning('Plot_Inj_Results:MdotCombined', 'Could not plot combined injector mass flow rates: %s', ME.message);
end

% -- Tab 2: Pressure -- % Renumbered from 2
try
    tabP = uitab(tabGroup, 'Title', 'Pressure');
    axP = uiaxes(tabP, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_P_t(axP, y);
catch ME
    warning('Plot_Inj_Results:Pressure', 'Could not plot injector pressure: %s', ME.message);
end

% -- Tab 3: Temperature --
try
    tabT = uitab(tabGroup, 'Title', 'Temperature');
    axT = uiaxes(tabT, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_T_t(axT, y);
catch ME
    warning('Plot_Inj_Results:Temperature', 'Could not plot injector temperature: %s', ME.message);
end

% -- Tab 4: State --
try
    tabState = uitab(tabGroup, 'Title', 'State');
    axState = uiaxes(tabState, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_State_t(axState, y);
catch ME
    warning('Plot_Inj_Results:State', 'Could not plot injector state: %s', ME.message);
end

% -- Tab 5: Quality --
try
    tabX = uitab(tabGroup, 'Title', 'Quality');
    axX = uiaxes(tabX, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_X_t(axX, y);
catch ME
    warning('Plot_Inj_Results:X', 'Could not plot injector quality: %s', ME.message);
end

% -- Tab 6: Density --
try
    tabRho = uitab(tabGroup, 'Title', 'Density');
    axRho = uiaxes(tabRho, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Rho_t(axRho, y);
catch ME
    warning('Plot_Inj_Results:Rho', 'Could not plot injector density: %s', ME.message);
end

% -- Tab 7: Specific Internal Energy --
try
    tabSpecU = uitab(tabGroup, 'Title', 'Specific Internal Energy');
    axSpecU = uiaxes(tabSpecU, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Spec_u_t(axSpecU, y);
catch ME
    warning('Plot_Inj_Results:SpecU', 'Could not plot injector specific internal energy: %s', ME.message);
end

% -- Tab 8: Specific Entropy --
try
    tabSpecS = uitab(tabGroup, 'Title', 'Specific Entropy');
    axSpecS = uiaxes(tabSpecS, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Spec_s_t(axSpecS, y);
catch ME
    warning('Plot_Inj_Results:SpecS', 'Could not plot injector specific entropy: %s', ME.message);
end

% -- Tab 9: Specific Enthalpy --
try
    tabSpecH = uitab(tabGroup, 'Title', 'Specific Enthalpy');
    axSpecH = uiaxes(tabSpecH, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Spec_h_t(axSpecH, y);
catch ME
    warning('Plot_Inj_Results:SpecH', 'Could not plot injector specific enthalpy: %s', ME.message);
end

% -- Tab 10: Specific Heat (cp) --
try
    tabCp = uitab(tabGroup, 'Title', 'Specific Heat (cp)');
    axCp = uiaxes(tabCp, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Spec_cp_t(axCp, y);
catch ME
    warning('Plot_Inj_Results:SpecCp', 'Could not plot injector specific heat cp: %s', ME.message);
end

% -- Tab 11: Specific Heat (cv) --
try
    tabCv = uitab(tabGroup, 'Title', 'Specific Heat (cv)');
    axCv = uiaxes(tabCv, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Spec_cv_t(axCv, y);
catch ME
    warning('Plot_Inj_Results:SpecCv', 'Could not plot injector specific heat cv: %s', ME.message);
end

% -- Tab 12: Critical Pressure Ratio --
try
    tabPcr = uitab(tabGroup, 'Title', 'Crit. Pressure Ratio');
    axPcr = uiaxes(tabPcr, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Ratio_Pcr_t(axPcr, y);
catch ME
    warning('Plot_Inj_Results:RatioPcr', 'Could not plot injector critical pressure ratio: %s', ME.message);
end

% -- Tab 13: Pressure Ratio --
try
    tabRatioP = uitab(tabGroup, 'Title', 'Pressure Ratio');
    axRatioP = uiaxes(tabRatioP, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Ratio_P_t(axRatioP, y);
catch ME
    warning('Plot_Inj_Results:RatioP', 'Could not plot injector pressure ratio: %s', ME.message);
end

% -- Tab 14: Kappa (NHNE) -- % Renumbered from 14
try
    tabKappa = uitab(tabGroup, 'Title', 'Kappa (NHNE)');
    axKappa = uiaxes(tabKappa, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Kappa_t(axKappa, y);
catch ME
    warning('Plot_Inj_Results:Kappa', 'Could not plot injector kappa: %s', ME.message);
end

% -- Tab 15: NHNE Mdot Components -- REMOVED

end 