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
    tabF = uitab(tabGroup, 'Title', 'F (Thrust, N)');
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

% 4. Exit Conditions Tab
if isfield(y.nozzle, 'Pe') && isfield(y.nozzle, 'Mode') && isfield(y, 'amb') && isfield(y.amb, 'P')
    tabExit = uitab(tabGroup, 'Title', 'Exit Conditions');
    axExit = uiaxes(tabExit, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Nozzle_Exit_t(axExit, y);
else
    missing_fields = {};
    if ~isfield(y.nozzle, 'Pe'); missing_fields{end+1} = 'y.nozzle.Pe'; end
    if ~isfield(y.nozzle, 'Mode'); missing_fields{end+1} = 'y.nozzle.Mode'; end
    if ~isfield(y, 'amb') || ~isfield(y.amb, 'P'); missing_fields{end+1} = 'y.amb.P'; end
    warning('Plot_Nozzle_Results:MissingExitData', 'Required field(s) not found: %s. Skipping exit conditions plot.', strjoin(missing_fields, ', '));
end

% 5. Mode Tab
if isfield(y.nozzle, 'Mode')
    tabMode = uitab(tabGroup, 'Title', 'Mode');
    axMode = uiaxes(tabMode, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Nozzle_Mode_t(axMode, y);
else
    warning('Plot_Nozzle_Results:MissingMode', 'y.nozzle.Mode not found. Skipping Mode plot.');
end

% 9. Nozzle Throat Pressure (Pt) Tab
if isfield(y.nozzle, 'Pt')
    tabPt = uitab(tabGroup, 'Title', 'Throat Pressure (Pt, bar)');
    axPt = uiaxes(tabPt, 'Units', 'normalized', 'Position', [0.1 0.1 0.85 0.8]);
    Plot_Nozzle_Pt_t(axPt, y);
else
    warning('Plot_Nozzle_Results:MissingPt', 'y.nozzle.Pt not found. Skipping Nozzle Throat Pressure plot.');
end

end 