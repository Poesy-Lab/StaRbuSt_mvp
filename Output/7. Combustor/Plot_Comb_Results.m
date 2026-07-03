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
    tabCstar = uitab(tabGroup, 'Title', 'c* (Theo & Actual)');
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

% 6. Molecular Weight (Mw) Tab
if isfield(y.comb, 'mw')
    tabMw = uitab(tabGroup, 'Title', 'Mw (kg/kmol)');
    axMw = uiaxes(tabMw, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_Mw_t(axMw, y);
else
    warning('Plot_Comb_Results:MissingMw', 'y.comb.mw not found. Skipping Mw plot.');
end

% 7. Specific Heat Ratio (Gamma) Tab
if isfield(y.comb, 'gamma')
    tabGamma = uitab(tabGroup, 'Title', 'Gamma (-)');
    axGamma = uiaxes(tabGamma, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_Gamma_t(axGamma, y);
else
    warning('Plot_Comb_Results:MissingGamma', 'y.comb.gamma not found. Skipping Gamma plot.');
end

% 8. Chamber Density (rho_c) Tab
if isfield(y.comb, 'rho_c')
    tabRhoC = uitab(tabGroup, 'Title', 'Density (kg/m^3)');
    axRhoC = uiaxes(tabRhoC, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_Rho_c_t(axRhoC, y);
else
    warning('Plot_Comb_Results:MissingRhoC', 'y.comb.rho_c not found. Skipping Chamber Density plot.');
end

% 10. Speed of Sound (SoS_c) Tab
if isfield(y.comb, 'SoS_c')
    tabSoSc = uitab(tabGroup, 'Title', 'SoS_c (m/s)');
    axSoSc = uiaxes(tabSoSc, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_SoS_c_t(axSoSc, y);
else
    warning('Plot_Comb_Results:MissingSoSc', 'y.comb.SoS_c not found. Skipping Speed of Sound plot.');
end

% 11. Specific Gas Constant (R_specific) Tab
if isfield(y.comb, 'R_specific')
    tabRspecific = uitab(tabGroup, 'Title', 'R_{specific} (J/kg*K)');
    axRspecific = uiaxes(tabRspecific, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_R_specific_t(axRspecific, y);
else
    warning('Plot_Comb_Results:MissingRspecific', 'y.comb.R_specific not found. Skipping Specific Gas Constant plot.');
end

% 12. Chamber Mach Number (Mach_c) Tab
if isfield(y.comb, 'Mach_c')
    tabMachc = uitab(tabGroup, 'Title', 'Mach_c (-)');
    axMachc = uiaxes(tabMachc, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_Mach_c_t(axMachc, y);
else
    warning('Plot_Comb_Results:MissingMachc', 'y.comb.Mach_c not found. Skipping Chamber Mach Number plot.');
end

% 13. Chamber Gas Velocity (Vc) Tab
if isfield(y.comb, 'Vc')
    tabVc = uitab(tabGroup, 'Title', 'Velocity (m/s)');
    axVc = uiaxes(tabVc, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Comb_Vc_t(axVc, y);
else
    warning('Plot_Comb_Results:MissingVc', 'y.comb.Vc not found. Skipping Chamber Gas Velocity plot.');
end

% 9. Acoustic Frequencies Tab
freq_fields_exist = isfield(y.comb, 'f_L1') || isfield(y.comb, 'f_L2') || ...
                    isfield(y.comb, 'f_H_pre_chamber') || isfield(y.comb, 'f_H_overall');

if freq_fields_exist
    % Check if at least one frequency field has non-NaN data to avoid empty plot tab
    has_f_L1_data = isfield(y.comb, 'f_L1') && ~isempty(y.comb.f_L1) && any(~isnan(y.comb.f_L1));
    has_f_L2_data = isfield(y.comb, 'f_L2') && ~isempty(y.comb.f_L2) && any(~isnan(y.comb.f_L2));
    has_f_H_pre_data = isfield(y.comb, 'f_H_pre_chamber') && ~isempty(y.comb.f_H_pre_chamber) && any(~isnan(y.comb.f_H_pre_chamber));
    has_f_H_overall_data = isfield(y.comb, 'f_H_overall') && ~isempty(y.comb.f_H_overall) && any(~isnan(y.comb.f_H_overall));

    if has_f_L1_data || has_f_L2_data || has_f_H_pre_data || has_f_H_overall_data
        tabFreq = uitab(tabGroup, 'Title', 'Frequency (Hz)');
        axFreq = uiaxes(tabFreq, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
        Plot_Comb_Frequency_t(axFreq, y);
    else
        warning('Plot_Comb_Results:NoFrequencyDataToPlot', 'Frequency fields found, but all contain only NaN values. Skipping Frequency plot tab.');
    end
else
    warning('Plot_Comb_Results:MissingFrequencyFields', 'No frequency data (f_L1, f_L2, f_H_pre_chamber, f_H_overall) found in y.comb. Skipping Frequency plot tab.');
end

end 