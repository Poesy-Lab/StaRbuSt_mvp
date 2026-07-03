---
tags:
  - 플롯
  - 탱크
  - 높이
  - 시각화
lastmod: 2025-04-30
---
# `Plot_Tank_h_t.m` 문서

## 함수 개요

`Plot_Tank_h_t` 함수는 주어진 `uiaxes` 핸들에 시간에 따른 탱크 내 액체 높이 및 총 유체 높이 변화를 플롯합니다.

```matlab
function Plot_Tank_h_t(ax, y)
```

## 입력값

-   `ax`: 그래프를 그릴 대상 `uiaxes` 핸들.
-   `y`: 시뮬레이션 결과 구조체. 다음 필드가 필요합니다:
    -   `y.time` (시간, 단위: s)
    -   `y.tank.m_l` (액체 질량, 단위: kg)
    -   `y.tank.rho_l` (액체 밀도, 단위: kg/m³)
    -   `y.tank.m_v` (증기 질량, 단위: kg)
    -   `y.tank.rho_v` (증기 밀도, 단위: kg/m³)
    -   `y.tank.A` (탱크 단면적, 단위: m²)

## 설명

`ax`로 지정된 `uiaxes` 객체에 액체 높이(`h_l`)와 총 유체 높이(`h_l + h_v`)를 `y.time`에 대해 플롯합니다. 높이는 부피 (질량/밀도)와 탱크 단면적으로부터 계산됩니다.

-   **플롯 스타일:**
    -   액체 높이: 파란색 실선 (`b-`), 선 굵기 1.5
    -   총 유체 높이: 빨간색 파선 (`r--`)
-   **부가 기능:** 그리드 표시, 범례 표시, 축 레이블 및 제목 설정. 필수 데이터 누락 시 경고 메시지를 표시하고 플롯 제목에 "(Data Missing)"을 추가합니다.
-   **동작 방식:** 새로운 Figure 창을 생성하지 않고 입력받은 `ax`에 직접 플롯합니다.

## 사용 예시 (`Plot_Tank_Results.m` 내)

```matlab
% fig가 uifigure이고 tabGroup이 uitabgroup이라고 가정
tabH = uitab(tabGroup, 'Title', 'Height');
axH = uiaxes(tabH, 'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]);
Plot_Tank_h_t(axH, y);
```

## 관련 항목 (See Also)

-   [[Plot_Tank_Results.m]] / [[Plot_Tank_Results.md]]
-   MATLAB 함수: `uiaxes`, `plot`, `xlabel`, `ylabel`, `title`, `grid`, `legend`, `hold`, `isfield`, `warning`, `strjoin`

# 전체 코드

```MATLAB
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
    plot(ax, y.time, h_total, 'r--'', 'DisplayName', 'Total Height (h_l + h_v)');
    hold(ax, 'off');
    grid(ax, 'on');
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Height (m)');
    title(ax, 'Tank Fluid Heights vs Time');
    legend(ax, 'Location', 'best');
    
end 