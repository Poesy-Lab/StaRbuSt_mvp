---
tags:
  - 플롯
  - 결과
  - 시각화
  - 메인
---
# 소개
- `PlotResults.m` 함수는 시뮬레이션 결과 구조체 `y`를 입력받아, 주요 컴포넌트별 플롯 생성 함수들을 호출하여 **시뮬레이션 결과에 대한 표준 그래프 세트를 생성**하는 메인 함수입니다.
- 이 함수는 탱크, 벤트 포트, 인젝터, 연료 그레인, 연소기, 노즐 등 각 주요 컴포넌트에 대한 `Plot_[ComponentName]_Results` 형태의 함수를 순차적으로 실행합니다.
- 각 `Plot_[ComponentName]_Results` 함수는 일반적으로 해당 컴포넌트의 다양한 변수들을 보여주는 여러 탭을 가진 Figure를 생성합니다.
- 각 플롯 함수 호출은 `try-catch` 블록으로 감싸져 있어, 특정 그래프 생성 중 오류가 발생해도 다른 그래프 생성은 계속 진행될 수 있습니다.

# Input

| 인수 | 설명                                                     |
| ---- | -------------------------------------------------------- |
| `y`  | 전체 시뮬레이션 결과 데이터가 포함된 구조체. 각 개별 플롯 함수가 요구하는 필드(예: `y.time`, `y.tank.P`, `y.comb.P` 등)를 모두 포함해야 합니다. |

# Output

- 함수 실행 시, 호출된 각 `Plot_[ComponentName]_Results` 함수에 의해 여러 개의 Figure 창이 생성되어 다양한 시뮬레이션 결과 그래프가 표시됩니다.

# 주요 호출 함수

이 함수는 다음과 같은 컴포넌트별 메인 플롯 함수들을 호출합니다:

- `Plot_Tank_Results(y)` - 탱크 관련 파라미터 플롯 (탭으로 구성)
- `Plot_Vent_Results(t, y)` - 벤트 포트 관련 파라미터 플롯 (탭으로 구성)
- `Plot_Inj_Results(y)` - 인젝터 관련 파라미터 플롯 (탭으로 구성)
- `Plot_Grain_Results(y)` - 연료 그레인 관련 파라미터 플롯 (탭으로 구성)
- `Plot_Comb_Results(y)` - 연소기 관련 파라미터 플롯 (탭으로 구성)
- `Plot_Nozzle_Results(y)` - 노즐 관련 파라미터 플롯 (탭으로 구성)

# 전체 코드

```MATLAB
function PlotResults(y)
%PlotResults Generates results plots by calling component-specific plotters.
%   Calls main plotting functions for each major component (Tank, Vent, etc.)
%   which generate figures with multiple tabs.
%
%   Input:
%       y: Simulation results structure (must contain y.time and other data).

% Note: Ensure that the necessary subfolders (e.g., 'Output/1. Tank',
% 'Output/2. Vent-port') are on the MATLAB path or added here/in the main script.

fprintf('\n--- Generating Simulation Result Plots ---\n');

% Extract time vector from the results structure
t = y.time;

% --- Tank Plots ---
% Calls Plot_Tank_Results which creates a tabbed figure for tank parameters
try
    fprintf('Generating Tank Plots...\n');
    Plot_Tank_Results(y); % Assumes y contains time data (y.time)
    fprintf('Tank plots generated successfully.\n');
catch ME
    warning('PlotResults:TankPlotsFailed', 'Could not generate tank plots: %s', ME.message);
end

% --- Vent Port Plots ---
% Calls Plot_Vent_Results which creates a tabbed figure for vent parameters
try
    fprintf('Generating Vent Port Plots...\n');
    Plot_Vent_Results(t, y); % Passes extracted t and y
    fprintf('Vent port plots generated successfully.\n');
catch ME
    warning('PlotResults:VentPlotsFailed', 'Could not generate vent port plots: %s', ME.message);
end

% --- Injector Plots ---
% Calls Plot_Inj_Results which creates a tabbed figure for injector parameters
try
    fprintf('Generating Injector Plots...\n');
    Plot_Inj_Results(y); % Assumes y contains time and injector data
    fprintf('Injector plots generated successfully.\n');
catch ME
    warning('PlotResults:InjectorPlotsFailed', 'Could not generate injector plots: %s', ME.message);
end

% --- Grain Plots ---
% Calls Plot_Grain_Results which creates a tabbed figure for grain parameters
try
    fprintf('Generating Grain Plots...\n');
    Plot_Grain_Results(y); % Assumes y contains time and fuel data
    fprintf('Grain plots generated successfully.\n');
catch ME
    warning('PlotResults:GrainPlotsFailed', 'Could not generate grain plots: %s', ME.message);
end

% --- Combustion Plots ---
% Calls Plot_Comb_Results which creates a tabbed figure for combustor parameters
try
    fprintf('Generating Combustion Plots...\n');
    Plot_Comb_Results(y); % Assumes y contains time and comb data
    fprintf('Combustion plots generated successfully.\n');
catch ME
    warning('PlotResults:CombPlotsFailed', 'Could not generate combustion plots: %s', ME.message);
end

% --- Nozzle Plots ---
% Calls Plot_Nozzle_Results which creates a tabbed figure for nozzle parameters
try
    fprintf('Generating Nozzle Plots...\n');
    Plot_Nozzle_Results(y); % Assumes y contains time and nozzle data
    fprintf('Nozzle plots generated successfully.\n');
catch ME
    warning('PlotResults:NozzlePlotsFailed', 'Could not generate nozzle plots: %s', ME.message);
end

% Optional: Bring all figures to front (might be annoying if many figures)
% figHandles = findall(0, 'Type', 'figure');
% if ~isempty(figHandles)
%     fprintf('Bringing plot windows to front...\n');
%     for i = 1:length(figHandles)
%         figure(figHandles(i));
%     end
% end

fprintf('--- Plot Generation Complete ---\n\n');

end 