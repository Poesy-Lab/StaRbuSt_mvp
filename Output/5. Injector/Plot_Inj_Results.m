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

% 데이터 존재 여부로 모델별 탭 표시 결정 (기록이 전부 NaN이면 해당 모델 미사용)
has_data = @(f) isfield(y, 'inj') && isfield(y.inj, f) && any(~isnan(y.inj.(f)));

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

% -- Tab 3: Temperature -- % Renumbered from 3
try
    tabT = uitab(tabGroup, 'Title', 'Temperature');
    axT = uiaxes(tabT, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_T_t(axT, y);
catch ME
    warning('Plot_Inj_Results:Temperature', 'Could not plot injector temperature: %s', ME.message);
end

% -- Tab 4: State -- % Renumbered from 4
try
    tabState = uitab(tabGroup, 'Title', 'State');
    axState = uiaxes(tabState, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_State_t(axState, y);
catch ME
    warning('Plot_Inj_Results:State', 'Could not plot injector state: %s', ME.message);
end

% -- Tab 5: Quality -- % Renumbered from 5
try
    tabX = uitab(tabGroup, 'Title', 'Quality');
    axX = uiaxes(tabX, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_X_t(axX, y);
catch ME
    warning('Plot_Inj_Results:Quality', 'Could not plot injector quality: %s', ME.message);
end

% -- Tab 6: Density -- % Renumbered from 6
try
    tabRho = uitab(tabGroup, 'Title', 'Density');
    axRho = uiaxes(tabRho, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Rho_t(axRho, y);
catch ME
    warning('Plot_Inj_Results:Density', 'Could not plot injector density: %s', ME.message);
end

% -- Tab 7: Specific Internal Energy -- % Renumbered from 7
try
    tabU = uitab(tabGroup, 'Title', 'Spec. Internal Energy');
    axU = uiaxes(tabU, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Spec_u_t(axU, y);
catch ME
    warning('Plot_Inj_Results:SpecU', 'Could not plot injector spec. internal energy: %s', ME.message);
end

% -- Tab 8: Specific Entropy -- % Renumbered from 8
try
    tabS = uitab(tabGroup, 'Title', 'Spec. Entropy');
    axS = uiaxes(tabS, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Spec_s_t(axS, y);
catch ME
    warning('Plot_Inj_Results:SpecS', 'Could not plot injector spec. entropy: %s', ME.message);
end

% -- Tab 9: Specific Enthalpy -- % Renumbered from 9
try
    tabH = uitab(tabGroup, 'Title', 'Spec. Enthalpy');
    axH = uiaxes(tabH, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Spec_h_t(axH, y);
catch ME
    warning('Plot_Inj_Results:SpecH', 'Could not plot injector spec. enthalpy: %s', ME.message);
end

% -- Tab 10: Specific Heat (cp) -- % Renumbered from 10
try
    tabCp = uitab(tabGroup, 'Title', 'Specific Heat (cp)');
    axCp = uiaxes(tabCp, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Spec_cp_t(axCp, y); % Call new cp function
catch ME
    warning('Plot_Inj_Results:SpecCp', 'Could not plot injector specific heat cp: %s', ME.message);
end

% -- Tab 11: Specific Heat (cv) -- % Renumbered from 11
try
    tabCv = uitab(tabGroup, 'Title', 'Specific Heat (cv)');
    axCv = uiaxes(tabCv, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Spec_cv_t(axCv, y); % Call new cv function
catch ME
    warning('Plot_Inj_Results:SpecCv', 'Could not plot injector specific heat cv: %s', ME.message);
end

% -- Tab 12: Critical Pressure Ratio -- % Renumbered from 12
try
    tabPcr = uitab(tabGroup, 'Title', 'Crit. Pressure Ratio');
    axPcr = uiaxes(tabPcr, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Ratio_Pcr_t(axPcr, y);
catch ME
    warning('Plot_Inj_Results:RatioPcr', 'Could not plot injector critical pressure ratio: %s', ME.message);
end

% -- Tab 13: Pressure Ratio -- % Renumbered from 13
try
    tabRatioP = uitab(tabGroup, 'Title', 'Pressure Ratio');
    axRatioP = uiaxes(tabRatioP, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_Ratio_P_t(axRatioP, y);
catch ME
    warning('Plot_Inj_Results:RatioP', 'Could not plot injector pressure ratio: %s', ME.message);
end

% -- Tab 14: Kappa (NHNE) -- NHNE 모델 사용 시에만 표시
if has_data('kappa')
    try
        tabKappa = uitab(tabGroup, 'Title', 'Kappa (NHNE)');
        axKappa = uiaxes(tabKappa, 'Units', 'normalized', 'Position', axesPosition);
        Plot_Inj_Kappa_t(axKappa, y);
    catch ME
        warning('Plot_Inj_Results:Kappa', 'Could not plot injector kappa: %s', ME.message);
    end
end

% -- Tab 14b: Void Fraction (FML) -- FML 모델 사용 시에만 표시
if has_data('alpha2')
    try
        tabAlpha2 = uitab(tabGroup, 'Title', 'Void Fraction (FML)');
        axAlpha2 = uiaxes(tabAlpha2, 'Units', 'normalized', 'Position', axesPosition);
        Plot_Inj_Alpha2_t(axAlpha2, y);
    catch ME
        warning('Plot_Inj_Results:Alpha2', 'Could not plot FML void fraction: %s', ME.message);
    end
end

% -- Tab 15: Injector Pressure Drop -- %
try
    tabDelP = uitab(tabGroup, 'Title', 'Injector Pressure Drop');
    axDelP = uiaxes(tabDelP, 'Units', 'normalized', 'Position', axesPosition);
    Plot_Inj_delP_t(axDelP, y); % Call the new pressure drop function
catch ME
    warning('Plot_Inj_Results:DelP', 'Could not plot injector pressure drop: %s', ME.message);
end

end