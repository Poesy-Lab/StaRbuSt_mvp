---
tags:
  - Output/Vent-port
  - Plotting
  - Vent-port
  - Pressure-Ratio
lastmod: 2025-04-30
---
# `Plot_Vent_Ratio_P_t.m`

 탱크 압력과 크리티컬 압력의 비율(`ratio_P = P_tank / P_cr`)을 시간에 따라 플로팅하는 함수입니다.

**의존성:**

*   입력 데이터 구조체 (`Output`)
*   `uitabgroup` 핸들 (`tabgroup`)
*   플로팅 옵션 구조체 (`PlotOption`)

**기능:**

1.  **탭 생성:** `tabgroup` 내에 'P Ratio (Vent)'라는 이름의 새 탭을 생성합니다.
2.  **축 생성:** 생성된 탭 내부에 `uiaxes`를 생성하여 플로팅 영역을 설정합니다.
3.  **데이터 플로팅:** 시간에 따른 `Output.vent.ratio_P` 데이터를 플로팅합니다.
4.  **축 레이블 및 제목 설정:** x축 레이블('Time (s)'), y축 레이블('Pressure Ratio (-)'), 플롯 제목('Vent Port Pressure Ratio (P/P_cr) vs. Time')을 설정합니다.
5.  **격자 표시:** 플롯에 격자를 추가합니다.
6.  **축 핸들 반환:** 생성된 `axes` 핸들을 반환합니다. (현재 코드에서는 반환하지 않음)

**사용 예시:**

```matlab
% 필요한 데이터 로드 또는 생성
load('simulation_output.mat'); % 예시 출력 파일

% PlotOption 설정 (예시)
PlotOption.figure = uifigure('Name', 'Simulation Results');
PlotOption.tabgroup = uitabgroup(PlotOption.figure, 'Position', [20 20 PlotOption.figure.Position(3)-40 PlotOption.figure.Position(4)-40]);

% 함수 호출
Plot_Vent_Ratio_P_t(Output, PlotOption.tabgroup, PlotOption);
```

**관련 파일:**

*   [[Plot_Vent_Results.m]]
*   [[Vent_ICF.m]]

# 전체 코드

```matlab
function ax = Plot_Vent_Ratio_P_t(Output, tabgroup, PlotOption)
% Plot Vent Port Pressure Ratio (P_tank / P_critical) vs. Time

% Create a new tab for the plot
tab = uitab(tabgroup, 'Title', 'P Ratio (Vent)');

% Create axes in the new tab
ax = uiaxes(tab); % Create axes in the tab

% Extract data
Time = Output.time;
ratio_P = Output.vent.ratio_P; % Ratio of Tank Pressure to Critical Pressure

% Plot data
plot(ax, Time, ratio_P, 'LineWidth', 1.5);

% Customize plot
xlabel(ax, 'Time (s)');
ylabel(ax, 'Pressure Ratio (-)');
title(ax, 'Vent Port Pressure Ratio (P/P_{cr}) vs. Time');
grid(ax, 'on');

end 