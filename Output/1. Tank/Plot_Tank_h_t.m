function Plot_Tank_h_t(ax, y)
    %Plot_Tank_h_t Plots tank liquid and total fluid heights over time.
    %   Calculates heights from volumes (mass/density) and tank area,
    %   then plots liquid height (h_l) and total height (h_l + h_v)
    %   against y.time on axes ax.
    %
    %   Inputs:
    %       ax: Axes handle to plot on.
    %       y: Simulation results structure (must contain time, tank.m_l,
    %          tank.rho_l, tank.m_v, tank.rho_v, tank.A).
    
    % Check if required fields exist
    required_fields = {'time', 'tank.m_l', 'tank.rho_l', 'tank.m_v', 'tank.rho_v', 'tank.A'};
    missing_fields = {};
    if ~isfield(y, 'time'); missing_fields{end+1} = 'y.time'; end
    if ~isfield(y, 'tank'); missing_fields{end+1} = 'y.tank';
    else
        if ~isfield(y.tank, 'm_l'); missing_fields{end+1} = 'y.tank.m_l'; end
        if ~isfield(y.tank, 'rho_l'); missing_fields{end+1} = 'y.tank.rho_l'; end
        if ~isfield(y.tank, 'm_v'); missing_fields{end+1} = 'y.tank.m_v'; end
        if ~isfield(y.tank, 'rho_v'); missing_fields{end+1} = 'y.tank.rho_v'; end
        if ~isfield(y.tank, 'A') || isempty(y.tank.A) || isnan(y.tank.A(1)) || y.tank.A(1) <= 0
            missing_fields{end+1} = 'y.tank.A (valid area)';
        end
    end
    
    if ~isempty(missing_fields)
        warning('Plot_Tank_h_t:MissingData', 'Cannot plot tank heights. Missing or invalid required data: %s. Check Init_Tank and System_old.', strjoin(missing_fields, ', '));
        title(ax, 'Tank Heights vs Time (Data Missing)');
        return; % Exit if data is missing or invalid
    end
    
    % Calculate volumes (element-wise)
    % Handle potential division by zero or NaN densities
    vol_l = y.tank.m_l ./ y.tank.rho_l;
    vol_v = y.tank.m_v ./ y.tank.rho_v;
    vol_l(isinf(vol_l) | isnan(vol_l)) = 0; % Set invalid volumes to 0
    vol_v(isinf(vol_v) | isnan(vol_v)) = 0; % Set invalid volumes to 0
    
    % Get tank area (should be constant)
    tank_area = y.tank.A(1);
    
    % Calculate heights
    h_l = vol_l / tank_area;
    h_v = vol_v / tank_area;
    h_total = h_l + h_v;
    
    % Plotting
    plot(ax, y.time, h_l, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Liquid Height (h_l)');
    hold(ax, 'on');
    plot(ax, y.time, h_total, 'r--', 'DisplayName', 'Total Height (h_l + h_v)');
    hold(ax, 'off');
    grid(ax, 'on');
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Height (m)');
    title(ax, 'Tank Fluid Heights vs Time');
    legend(ax, 'Location', 'best');
    
    end