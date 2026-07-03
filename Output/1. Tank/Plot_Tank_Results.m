function Plot_Tank_Results(y)
%Plot_Tank_Results Generates all standard tank-related plots in a single
%   figure window with tabs using uifigure and uitabgroup.
%
%   Input:
%       y: Simulation results structure containing time and tank data.

% --- Close existing figure with the same name ---
figName = 'Tank Simulation Results';
existingFigs = findall(0, 'Type', 'figure', 'Name', figName);
if ~isempty(existingFigs)
    fprintf('Closing existing ''%s'' figure window(s).\n', figName);
    close(existingFigs);
end
% --- 추가된 부분 끝 ---

fprintf('Generating Combined Tank Plots in Tabbed Figure...\n');

fig = uifigure('Name', figName, 'Position', [100, 100, 800, 600]);
tabGroup = uitabgroup(fig, 'Position', [20, 20, 760, 560]);

% Define axes position to fill tab better (normalized units)
axesPosition = [0.07, 0.12, 0.88, 0.8];

% --- Tank Pressure Tab ---
try
    tabP = uitab(tabGroup, 'Title', 'Pressure');
    axP = uiaxes(tabP, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_P_t(axP, y); % Call individual function

    % --- 테스트 코드 시작 ---
    % plot(axP, 1:10, (1:10).^2, 'r-o'); % 간단한 테스트 플롯
    % title(axP, 'Test Plot in Pressure Tab');
    % xlabel(axP, 'X-axis');
    % ylabel(axP, 'Y-axis');
    % grid(axP, 'on');
    % --- 테스트 코드 끝 ---
catch ME
    warning('Plot_Tank_Results:TankPressure', 'Could not plot tank pressure: %s', ME.message);
end

% --- Tank Temperature Tab ---
try
    tabT = uitab(tabGroup, 'Title', 'Temperature');
    axT = uiaxes(tabT, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_T_t(axT, y); % Call individual function
catch ME
    warning('Plot_Tank_Results:TankTemperature', 'Could not plot tank temperature: %s', ME.message);
end

% --- Tank Quality Tab ---
try
    tabX = uitab(tabGroup, 'Title', 'Quality');
    axX = uiaxes(tabX, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_X_t(axX, y); % Call individual function
catch ME
    warning('Plot_Tank_Results:TankQuality', 'Could not plot tank quality: %s', ME.message);
end

% --- Tank Mass Tab ---
try
    tabM = uitab(tabGroup, 'Title', 'Mass');
    axM = uiaxes(tabM, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_m_t(axM, y); % Call individual function
catch ME
    warning('Plot_Tank_Results:TankMasses', 'Could not plot tank masses: %s', ME.message);
end

% --- Tank Density Tab ---
try
    tabRho = uitab(tabGroup, 'Title', 'Density');
    axRho = uiaxes(tabRho, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_Rho_t(axRho, y); % Call individual function
catch ME
    warning('Plot_Tank_Results:TankDensities', 'Could not plot tank densities: %s', ME.message);
end

% --- Tank Specific Internal Energy Tab ---
try
    tabU = uitab(tabGroup, 'Title', 'Specific Internal Energy');
    axU = uiaxes(tabU, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_Spec_u_t(axU, y); % Call individual function
catch ME
    warning('Plot_Tank_Results:TankSpecU', 'Could not plot tank specific internal energies: %s', ME.message);
end

% --- Tank Specific Entropy Tab ---
try
    tabS = uitab(tabGroup, 'Title', 'Specific Entropy');
    axS = uiaxes(tabS, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_Spec_s_t(axS, y); % Call individual function
catch ME
    warning('Plot_Tank_Results:TankSpecS', 'Could not plot tank specific entropies: %s', ME.message);
end

% --- Tank Specific Enthalpy Tab ---
try
    tabH = uitab(tabGroup, 'Title', 'Specific Enthalpy');
    axH = uiaxes(tabH, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_Spec_h_t(axH, y); % Call individual function
catch ME
    warning('Plot_Tank_Results:TankSpecH', 'Could not plot tank specific enthalpies: %s', ME.message);
end

% --- Tank Specific Heat (cp) Tab ---
try
    tabCp = uitab(tabGroup, 'Title', 'Specific Heat (cp)');
    axCp = uiaxes(tabCp, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_Spec_cp_t(axCp, y); % Call new individual function
catch ME
    warning('Plot_Tank_Results:TankSpecCp', 'Could not plot tank specific heat cp: %s', ME.message);
end

% --- Tank Specific Heat (cv) Tab ---
try
    tabCv = uitab(tabGroup, 'Title', 'Specific Heat (cv)');
    axCv = uiaxes(tabCv, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_Spec_cv_t(axCv, y); % Call new individual function
catch ME
    warning('Plot_Tank_Results:TankSpecCv', 'Could not plot tank specific heat cv: %s', ME.message);
end

% --- Tank Total Entropy Tab ---
try
    tabTotalS = uitab(tabGroup, 'Title', 'Total Entropy');
    axTotalS = uiaxes(tabTotalS, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_Total_S_t(axTotalS, y); % Call new individual function
catch ME
    warning('Plot_Tank_Results:TankTotalS', 'Could not plot tank total entropy: %s', ME.message);
end

% --- Tank Total Enthalpy Tab ---
try
    tabTotalH = uitab(tabGroup, 'Title', 'Total Enthalpy');
    axTotalH = uiaxes(tabTotalH, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_Total_H_t(axTotalH, y); % Call new individual function
catch ME
    warning('Plot_Tank_Results:TankTotalH', 'Could not plot tank total enthalpy: %s', ME.message);
end

% --- Tank Height Tab (New) ---
try
    tabHgt = uitab(tabGroup, 'Title', 'Height');
    axHgt = uiaxes(tabHgt, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Tank_h_t(axHgt, y);
catch ME
    warning('Plot_Tank_Results:TankHeight', 'Could not plot tank heights: %s', ME.message);
end


fprintf('Combined tank plots generation complete.\n');

end 