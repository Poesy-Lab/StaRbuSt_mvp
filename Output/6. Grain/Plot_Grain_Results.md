---
lastmod: 2025-04-30
tags:
  - plot
  - grain
  - main
  - output
---


# Plot_Grain_Results.m

Grain 컴포넌트의 시뮬레이션 결과 (`Gox`, `rdot`, `mdot`)를 탭으로 구성된 Figure 창에 플로팅하는 메인 함수입니다.

## 입력

*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.fuel` 필드 포함해야 함)

## 출력

탭으로 구성된 Figure 창을 생성하여 각 탭에 Grain 관련 파라미터 그래프를 표시합니다.

## 호출하는 함수

*   [[Output/6. Grain/Plot_Grain_Gox_t.m|Plot_Grain_Gox_t.m]]
*   [[Output/6. Grain/Plot_Grain_Rdot_t.m|Plot_Grain_Rdot_t.m]]
*   [[Output/6. Grain/Plot_Grain_Mdot_t.m|Plot_Grain_Mdot_t.m]]

## 관련 파일

*   [[Output/PlotResults.m|PlotResults.m]] (호출됨)
*   [[Components/6. Grain/Grain_aGn.m|Grain_aGn.m]]

## # 전체 코드

```matlab
function Plot_Grain_Results(y)
%Plot_Grain_Results Creates a tabbed figure for Grain simulation results.
%   Generates a figure window with multiple tabs, each displaying a 
%   different grain parameter plot (Gox, rdot, mdot) vs time.
%
%   Input:
%       y: Simulation results structure (must contain y.time and y.fuel data).

% Check if y.fuel exists
if ~isfield(y, 'fuel')
    warning('Plot_Grain_Results:MissingFuelData', 'y.fuel structure not found. Skipping grain plots.');
    return;
end

% Define the figure name
figName = 'Grain Simulation Results';

% --- Close existing figure with the same name --- 
existingFigs = findall(0, 'Type', 'Figure', 'Name', figName);
if ~isempty(existingFigs)
    fprintf('Closing existing \'%s\' figure...\n', figName);
    close(existingFigs);
end

% --- Create Figure and Tab Group --- 
fig = uifigure('Name', figName, 'Position', [150 150 800 600]);
tabGroup = uitabgroup(fig, 'Position', [20 20 fig.Position(3)-40 fig.Position(4)-40]);

% --- Create Tabs and Plot --- 

% 1. Gox Tab
if isfield(y.fuel, 'Gox')
    tabGox = uitab(tabGroup, 'Title', 'Gox (Oxidizer Flux)');
    axGox = uiaxes(tabGox, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Grain_Gox_t(axGox, y);
else
    warning('Plot_Grain_Results:MissingGox', 'y.fuel.Gox not found. Skipping Gox plot.');
end

% 2. Rdot Tab
if isfield(y.fuel, 'rdot')
    tabRdot = uitab(tabGroup, 'Title', 'rdot (Regression Rate)');
    axRdot = uiaxes(tabRdot, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Grain_Rdot_t(axRdot, y);
else
    warning('Plot_Grain_Results:MissingRdot', 'y.fuel.rdot not found. Skipping rdot plot.');
end

% 3. Mdot Tab
if isfield(y.fuel, 'mdot')
    tabMdot = uitab(tabGroup, 'Title', 'mdot (Fuel Flow Rate)');
    axMdot = uiaxes(tabMdot, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Grain_Mdot_t(axMdot, y);
else
    warning('Plot_Grain_Results:MissingMdot', 'y.fuel.mdot not found. Skipping mdot plot.');
end

end
``` 