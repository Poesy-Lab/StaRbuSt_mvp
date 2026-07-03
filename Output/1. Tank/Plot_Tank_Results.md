---
tags:
  - 플롯
  - 탱크
  - 결과
  - 시각화
  - 메인
  - UI
lastmod: {{date}}
---
# `Plot_Tank_Results.m` 문서

## 함수 개요

`Plot_Tank_Results` 함수는 시뮬레이션 결과 구조체 `y`를 입력받아, 탱크와 관련된 표준 그래프 세트를 하나의 `uifigure` 창 내에 탭으로 구성하여 생성합니다. 각 탭에는 개별 플롯 함수(예: `Plot_Tank_P_t`)가 호출되어 해당 그래프가 그려집니다.

```matlab
function Plot_Tank_Results(y)
```

## 입력값

-   `y`: 시뮬레이션 결과 구조체. 각 개별 플롯 함수가 요구하는 `y.time` 및 `y.tank` 하위 필드들을 포함해야 합니다.

## 설명

이 함수는 'Tank Simulation Results'라는 제목의 `uifigure` 창과 그 안에 `uitabgroup`을 생성합니다. 각 파라미터(압력, 온도 등)에 대해 별도의 탭(`uitab`)과 그 안에 그래프 영역(`uiaxes`)을 만듭니다.

-   **레이아웃:** `uiaxes`는 `'Units', 'normalized', 'Position', [0.07, 0.12, 0.88, 0.8]` 설정을 통해 탭 내부에 적절한 여백을 두고 배치됩니다.
-   **모듈성:** 각 탭의 그래프는 해당하는 개별 플롯 함수(`Plot_Tank_..._t.m`)를 호출하여 그려집니다. 이때 생성된 `uiaxes` 핸들과 `y` 구조체가 전달됩니다.
-   **오류 처리:** 각 플롯 함수 호출은 `try...catch` 블록으로 감싸져 있어, 특정 그래프 생성 오류 발생 시 경고만 표시하고 전체 실행이 중단되지 않습니다.
-   **부가 기능:** 개별 플롯 함수 내에서 단위 변환(예: Pa->MPa), 라인 스타일 지정, 범례/그리드 표시 등이 처리됩니다.

## 사용 예시 (`Test_StaRbuSt.m` 내)

```matlab
% y가 System(x)로부터 반환된 출력 구조체라고 가정
fprintf('\n--- Post-Processing ---\n');
Plot_Tank_Results(y); % 메인 플롯 함수 호출
```

## 관련 항목 (See Also)

-   개별 플롯 함수:
    -   [[Plot_Tank_P_t.m]] / [[Plot_Tank_P_t.md]]
    -   [[Plot_Tank_T_t.m]] / [[Plot_Tank_T_t.md]]
    -   [[Plot_Tank_X_t.m]] / [[Plot_Tank_X_t.md]]
    -   [[Plot_Tank_m_t.m]] / [[Plot_Tank_m_t.md]]
    -   [[Plot_Tank_Rho_t.m]] / [[Plot_Tank_Rho_t.md]]
    -   [[Plot_Tank_Spec_u_t.m]] / [[Plot_Tank_Spec_u_t.md]]
    -   [[Plot_Tank_Spec_s_t.m]] / [[Plot_Tank_Spec_s_t.md]]
    -   [[Plot_Tank_Spec_h_t.m]] / [[Plot_Tank_Spec_h_t.md]]
    -   [[Plot_Tank_Spec_cp_t.m]] / [[Plot_Tank_Spec_cp_t.md]]
    -   [[Plot_Tank_Spec_cv_t.m]] / [[Plot_Tank_Spec_cv_t.md]]
    -   [[Plot_Tank_Total_S_t.m]] / [[Plot_Tank_Total_S_t.md]]
    -   [[Plot_Tank_Total_H_t.m]] / [[Plot_Tank_Total_H_t.md]]
-   MATLAB 함수: `uifigure`, `uitabgroup`, `uitab`, `uiaxes`

# 전체 코드

```MATLAB
function Plot_Tank_Results(y)
%Plot_Tank_Results Generates all standard tank-related plots in a single
%   figure window with tabs using uifigure and uitabgroup.
%
%   Input:
%       y: Simulation results structure containing time and tank data.

fprintf('Generating Combined Tank Plots in Tabbed Figure...\n');

fig = uifigure('Name', 'Tank Simulation Results', 'Position', [100, 100, 800, 600]);
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


fprintf('Combined tank plots generation complete.\n');

end 