---
lastmod: 2025-04-30
tags:
  - plot
  - combustor
  - main
  - output
---

# Plot_Comb_Results.m

Combustor 컴포넌트의 시뮬레이션 결과 (`mdot`, `OF`, `cstar`, `P`, `T`)를 탭으로 구성된 Figure 창에 플로팅하는 메인 함수입니다.

## 입력

*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.comb` 필드 포함해야 함)

## 출력

탭으로 구성된 Figure 창을 생성하여 각 탭에 Combustor 관련 파라미터 그래프를 표시합니다.

## 호출하는 함수

*   [[Output/7. Combustor/Plot_Comb_Mdot_t.m|Plot_Comb_Mdot_t.m]]
*   [[Output/7. Combustor/Plot_Comb_OF_t.m|Plot_Comb_OF_t.m]]
*   [[Output/7. Combustor/Plot_Comb_Cstar_t.m|Plot_Comb_Cstar_t.m]]
*   [[Output/7. Combustor/Plot_Comb_P_t.m|Plot_Comb_P_t.m]]
*   [[Output/7. Combustor/Plot_Comb_T_t.m|Plot_Comb_T_t.m]]

## 관련 파일

*   [[Output/PlotResults.m|PlotResults.m]] (호출됨)
*   [[Components/7. Combustor/Comb_Itercalc.m|Comb_Itercalc.m]]

## # 전체 코드

```matlab
function Plot_Comb_Results(y)
%Plot_Comb_Results Creates a tabbed figure for Combustor simulation results.
%   Generates a figure window with multiple tabs, each displaying a 
%   different combustor parameter plot (mdot, OF, cstar, P, T) vs time.
%
%   Input:
%       y: Simulation results structure (must contain y.time and y.comb data).

% Check if y.comb exists
if ~isfield(y, 'comb')
    warning('Plot_Comb_Results:MissingCombData', 'y.comb structure not found. Skipping combustor plots.');
    return;
end

% Define the figure name
figName = 'Combustor Simulation Results';

% --- Close existing figure with the same name --- 
existingFigs = findall(0, 'Type', 'Figure', 'Name', figName);
if ~isempty(existingFigs)
    fprintf('Closing existing ''%s'' figure...\n', figName);
    close(existingFigs);
end

% --- Create Figure and Tab Group --- 
fig = uifigure('Name', figName, 'Position', [200 200 800 600]); % Adjusted position slightly
tabGroup = uitabgroup(fig, 'Position', [20 20 fig.Position(3)-40 fig.Position(4)-40]);

% --- Create Tabs and Plot --- 

% 1. Mdot Tab
if isfield(y.comb, 'mdot')
    tabMdot = uitab(tabGroup, 'Title', 'mdot (Flow Rate)');
    axMdot = uiaxes(tabMdot, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_Mdot_t(axMdot, y);
else
    warning('Plot_Comb_Results:MissingMdot', 'y.comb.mdot not found. Skipping mdot plot.');
end

% 2. O/F Ratio Tab
if isfield(y.comb, 'OF')
    tabOF = uitab(tabGroup, 'Title', 'O/F Ratio');
    axOF = uiaxes(tabOF, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_OF_t(axOF, y);
else
    warning('Plot_Comb_Results:MissingOF', 'y.comb.OF not found. Skipping O/F plot.');
end

% 3. C* Tab
if isfield(y.comb, 'cstar')
    tabCstar = uitab(tabGroup, 'Title', 'c* (Characteristic Velocity)');
    axCstar = uiaxes(tabCstar, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_Cstar_t(axCstar, y);
else
    warning('Plot_Comb_Results:MissingCstar', 'y.comb.cstar not found. Skipping c* plot.');
end

% 4. Pressure Tab
if isfield(y.comb, 'P')
    tabP = uitab(tabGroup, 'Title', 'Pressure (bar)');
    axP = uiaxes(tabP, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_P_t(axP, y);
else
    warning('Plot_Comb_Results:MissingP', 'y.comb.P not found. Skipping pressure plot.');
end

% 5. Temperature Tab
if isfield(y.comb, 'T')
    tabT = uitab(tabGroup, 'Title', 'Temperature (°C)');
    axT = uiaxes(tabT, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_T_t(axT, y);
else
    warning('Plot_Comb_Results:MissingT', 'y.comb.T not found. Skipping temperature plot.');
end

end 