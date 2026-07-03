function fig = Plot_Vent_Results(t, y)
% Plot_Vent_Results Creates a figure with tabs for vent port simulation results.
%
% Args:
%   t (double): Time vector (s).
%   y (struct): Simulation results structure containing y.vent data.
%
% Returns:
%   fig (figure): Handle to the created figure.

% Check if a figure with the same name already exists and close it
fig_name = 'Vent Port Simulation Results';
existing_figs = findall(0, 'Type', 'figure', 'Name', fig_name);
if ~isempty(existing_figs)
    fprintf('Closing existing figure: ''%s''\n', fig_name);
    close(existing_figs);
end

% Create a new figure
fig = uifigure('Name', fig_name, 'Position', [200, 200, 700, 500]);

% Create a TabGroup
tabGroup = uitabgroup(fig, 'Position', [20, 20, 660, 460]);

% -- Tab 1: Critical Pressure Ratio --
tabPcr = uitab(tabGroup, 'Title', 'Critical Pressure Ratio');
axPcr = uiaxes(tabPcr, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Vent_Ratio_Pcr_t(axPcr, struct('time', t, 'vent', y.vent)); % Pass t explicitly as y.time

% -- Tab 2: Pressure Ratio (Pamb/Ptank) --
tabP = uitab(tabGroup, 'Title', 'Pressure Ratio (Pamb/Ptank)');
axP = uiaxes(tabP, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Vent_Ratio_P_t(axP, struct('time', t, 'vent', y.vent)); % Pass t explicitly as y.time

% -- Tab 3: Mass Flow Rate --
tabMdot = uitab(tabGroup, 'Title', 'Mass Flow Rate');
axMdot = uiaxes(tabMdot, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Vent_Mdot_t(axMdot, struct('time', t, 'vent', y.vent)); % Pass t explicitly as y.time

end 