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

% --- Tank Height Plot (New) <-- 이 섹션 전체 삭제 ---
% try
%     fprintf('Generating Tank Height Plot...\n');
%     fig_tank_h = figure('Name', 'Tank Height Results', 'NumberTitle', 'off'); % 새 Figure 생성
%     ax_tank_h = axes(fig_tank_h); % Figure에서 Axes 핸들 가져오기
%     Plot_Tank_h_t(ax_tank_h, y); % 새 함수 호출
%     fprintf('Tank height plot generated successfully.\n');
% catch ME
%     warning('PlotResults:TankHeightPlotFailed', 'Could not generate tank height plot: %s', ME.message);
%     if exist('fig_tank_h', 'var') && ishandle(fig_tank_h)
%         clf(fig_tank_h); % 오류 시 Figure 내용 지우기
%         title(ax_tank_h, 'Tank Height Plot Failed');
%     end
% end

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
if isfield(y, 'fuel') && isfield(y.fuel, 'mdot') && any(y.fuel.mdot > 0)
    try
        fprintf('Generating Grain Plots...\n');
        Plot_Grain_Results(y); % Assumes y contains time and fuel data
        fprintf('Grain plots generated successfully.\n');
    catch ME
        warning('PlotResults:GrainPlotsFailed', 'Could not generate grain plots: %s', ME.message);
    end
else
    fprintf('Skipping Grain plots: No fuel mass flow data found (likely Spray Test mode).\n');
end

% --- Combustion Plots ---
% Calls Plot_Comb_Results which creates a tabbed figure for combustor parameters
if isfield(y, 'comb') && isfield(y.comb, 'mdot') && any(y.comb.mdot > 0)
    try
        fprintf('Generating Combustion Plots...\n');
        Plot_Comb_Results(y); % Assumes y contains time and comb data
        fprintf('Combustion plots generated successfully.\n');
    catch ME
        warning('PlotResults:CombPlotsFailed', 'Could not generate combustion plots: %s', ME.message);
    end
else
    fprintf('Skipping Combustion plots: No combustion mass flow data found (likely Spray Test mode).\n');
end

% --- Nozzle Plots ---
% Calls Plot_Nozzle_Results which creates a tabbed figure for nozzle parameters
if isfield(y, 'nozzle') && isfield(y.nozzle, 'F') && any(y.nozzle.F > 0)
    try
        fprintf('Generating Nozzle Plots...\n');
        Plot_Nozzle_Results(y); % Assumes y contains time and nozzle data
        fprintf('Nozzle plots generated successfully.\n');
    catch ME
        warning('PlotResults:NozzlePlotsFailed', 'Could not generate nozzle plots: %s', ME.message);
    end
else
    fprintf('Skipping Nozzle plots: No thrust data found (likely Spray Test mode).\n');
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