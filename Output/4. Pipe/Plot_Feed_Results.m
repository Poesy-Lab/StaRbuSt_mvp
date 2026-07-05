function fig = Plot_Feed_Results(y)
%Plot_Feed_Results Creates a figure with tabs for feed line simulation results.
%   공급 라인(탱크-인젝터 배관) 결과 탭 창: 라인 압력, 압력손실, 출구 건도.
%
% Args:
%   y (struct): Simulation results structure containing y.time, y.feed, y.tank.
%
% Returns:
%   fig (figure): Handle to the created figure.

% Check if a figure with the same name already exists and close it
fig_name = 'Feed Line Simulation Results';
existing_figs = findall(0, 'Type', 'figure', 'Name', fig_name);
if ~isempty(existing_figs)
    fprintf('Closing existing figure: ''%s''\n', fig_name);
    close(existing_figs);
end

% Create a new figure
fig = uifigure('Name', fig_name, 'Position', [340, 190, 700, 500]);

% Create a TabGroup
tabGroup = uitabgroup(fig, 'Position', [20, 20, 660, 460]);

% Define axes position
axesPosition = [0.07, 0.12, 0.88, 0.8];

% -- Tab 1: Line Pressures (탱크압 vs 라인 출구압 = 인젝터 전방압) --
try
    tabP = uitab(tabGroup, 'Title', 'Line Pressures');
    axP = uiaxes(tabP, 'Units', 'normalized', 'Position', axesPosition);
    plot(axP, y.time, y.tank.P / 1e5, 'Color', [0 0.4470 0.7410], 'LineWidth', 1.8, 'DisplayName', 'P_{tank}');
    hold(axP, 'on');
    plot(axP, y.time, y.feed.P_out / 1e5, 'r-', 'LineWidth', 1.8, 'DisplayName', 'P_{line,out} (injector inlet)');
    hold(axP, 'off');
    grid(axP, 'on');
    xlabel(axP, 'Time (s)');
    ylabel(axP, 'Pressure (bar)');
    title(axP, 'Tank / Line Outlet Pressure vs Time');
    legend(axP, 'show', 'Location', 'best');
catch ME
    warning('Plot_Feed_Results:Pressures', 'Could not plot line pressures: %s', ME.message);
end

% -- Tab 2: Line Pressure Drop --
try
    tabDp = uitab(tabGroup, 'Title', 'Pressure Drop');
    axDp = uiaxes(tabDp, 'Units', 'normalized', 'Position', axesPosition);
    plot(axDp, y.time, y.feed.dP_line / 1e5, 'Color', [0.4940 0.1840 0.5560], 'LineWidth', 1.8);
    grid(axDp, 'on');
    xlabel(axDp, 'Time (s)');
    ylabel(axDp, '\DeltaP_{line} (bar)');
    title(axDp, 'Feed Line Total Pressure Drop vs Time');
catch ME
    warning('Plot_Feed_Results:PressureDrop', 'Could not plot line pressure drop: %s', ME.message);
end

% -- Tab 3: Outlet Quality (라인 플래싱 진단 = 인젝터 입구 건도) --
try
    tabX = uitab(tabGroup, 'Title', 'Outlet Quality');
    axX = uiaxes(tabX, 'Units', 'normalized', 'Position', axesPosition);
    plot(axX, y.time, y.feed.x_out, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.8);
    grid(axX, 'on');
    xlabel(axX, 'Time (s)');
    ylabel(axX, 'Quality x_{out} (-)');
    title(axX, 'Line Outlet (Injector Inlet) Quality vs Time');
catch ME
    warning('Plot_Feed_Results:Quality', 'Could not plot line outlet quality: %s', ME.message);
end

end
