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
    fprintf('Closing existing ''%s'' figure...\n', figName);
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

% 4. R (Port Radius) Tab
if isfield(y.fuel, 'R')
    tabR = uitab(tabGroup, 'Title', 'R (Port Radius)');
    axR = uiaxes(tabR, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Grain_R_t(axR, y);
else
    warning('Plot_Grain_Results:MissingR', 'y.fuel.R not found. Skipping R plot.');
end

% 5. Ap (Port Area) Tab
if isfield(y.fuel, 'Ap')
    tabAp = uitab(tabGroup, 'Title', 'Ap (Port Area)');
    axAp = uiaxes(tabAp, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Grain_Ap_t(axAp, y);
else
    warning('Plot_Grain_Results:MissingAp', 'y.fuel.Ap not found. Skipping Ap plot.');
end

% 6. Ab (Burn Area) Tab
if isfield(y.fuel, 'Ab')
    tabAb = uitab(tabGroup, 'Title', 'Ab (Burn Area)');
    axAb = uiaxes(tabAb, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Grain_Ab_t(axAb, y);
else
    warning('Plot_Grain_Results:MissingAb', 'y.fuel.Ab not found. Skipping Ab plot.');
end

% 7. dR_m (Radius Change per Step) Tab
if isfield(y.fuel, 'dR_m')
    tabdRm = uitab(tabGroup, 'Title', 'dR_m (Radius Change / Step)');
    axdRm = uiaxes(tabdRm, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Grain_dRm_t(axdRm, y);
else
    warning('Plot_Grain_Results:MissingdRm', 'y.fuel.dR_m not found. Skipping dR_m plot.');
end

end 