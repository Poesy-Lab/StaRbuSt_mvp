---
lastmod: 2025-04-30
tags:
  - plot
  - nozzle
  - main
  - output
---

# Plot_Nozzle_Results.m

Nozzle 컴포넌트의 시뮬레이션 결과 (`Cf`, `F`, `Isp_sl`)를 탭으로 구성된 Figure 창에 플로팅하는 메인 함수입니다.

## 입력

*   `y`: 시뮬레이션 결과 구조체 ( `y.time`, `y.nozzle` 필드 포함해야 함)

## 출력

탭으로 구성된 Figure 창을 생성하여 각 탭에 Nozzle 관련 파라미터 그래프를 표시합니다.

## 호출하는 함수

*   [[Output/8. Nozzle/Plot_Nozzle_Cf_t.m|Plot_Nozzle_Cf_t.m]]
*   [[Output/8. Nozzle/Plot_Nozzle_F_t.m|Plot_Nozzle_F_t.m]]
*   [[Output/8. Nozzle/Plot_Nozzle_Isp_sl_t.m|Plot_Nozzle_Isp_sl_t.m]]

## 관련 파일

*   [[Output/PlotResults.m|PlotResults.m]] (호출됨)
*   [[Components/8. Nozzle/Nozzle.m|Nozzle.m]]

## # 전체 코드

```matlab
function Plot_Nozzle_Results(y)
%Plot_Nozzle_Results Creates a tabbed figure for Nozzle simulation results.
%   Generates a figure window with multiple tabs, each displaying a 
%   different nozzle parameter plot (Cf, F, Isp_sl) vs time.
%
%   Input:
%       y: Simulation results structure (must contain y.time and y.nozzle data).

% Check if y.nozzle exists
if ~isfield(y, 'nozzle')
    warning('Plot_Nozzle_Results:MissingNozzleData', 'y.nozzle structure not found. Skipping nozzle plots.');
    return;
end

% Define the figure name
figName = 'Nozzle Simulation Results';

% --- Close existing figure with the same name --- 
existingFigs = findall(0, 'Type', 'Figure', 'Name', figName);
if ~isempty(existingFigs)
    fprintf('Closing existing ''%s'' figure...\n', figName);
    close(existingFigs);
end

% --- Create Figure and Tab Group --- 
fig = uifigure('Name', figName, 'Position', [250 250 800 600]); % Adjusted position slightly
tabGroup = uitabgroup(fig, 'Position', [20 20 fig.Position(3)-40 fig.Position(4)-40]);

% --- Create Tabs and Plot --- 

% 1. Cf Tab
if isfield(y.nozzle, 'Cf')
    tabCf = uitab(tabGroup, 'Title', 'Cf (Thrust Coeff.)');
    axCf = uiaxes(tabCf, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Nozzle_Cf_t(axCf, y);
else
    warning('Plot_Nozzle_Results:MissingCf', 'y.nozzle.Cf not found. Skipping Cf plot.');
end

% 2. F Tab
if isfield(y.nozzle, 'F')
    tabF = uitab(tabGroup, 'Title', 'F (Thrust, kN)');
    axF = uiaxes(tabF, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Nozzle_F_t(axF, y);
else
    warning('Plot_Nozzle_Results:MissingF', 'y.nozzle.F not found. Skipping thrust plot.');
end

% 3. Isp_sl Tab
if isfield(y.nozzle, 'Isp_sl')
    tabIsp = uitab(tabGroup, 'Title', 'Isp (Sea Level, s)');
    axIsp = uiaxes(tabIsp, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Nozzle_Isp_sl_t(axIsp, y);
else
    warning('Plot_Nozzle_Results:MissingIsp', 'y.nozzle.Isp_sl not found. Skipping sea level Isp plot.');
end

end
``` 