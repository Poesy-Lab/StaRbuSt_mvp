---
tags:
  - 연소실
  - 연소생성물
  - 물성치
  - 분자량
  - 비열비
  - 밀도
Author: Gemini AI (Generated)
---
# 소개
- `Comb_param.m`은 **입력된 연소실 압력($P_c$), 혼합비(OF), 노즐 팽창비($\\varepsilon$) 및 CEA 객체를 기반으로 연소실 내 연소 생성물의 주요 열역학적 물성치인 분자량($M_w$), 비열비($\\gamma_c$), 밀도($\\rho_c$)를 계산**하는 함수입니다.
- 이 함수는 일반적으로 `Comb_Itercalc.m`을 통해 연소압과 O/F비가 결정된 후, 그리고 `Nozzle.m`에서 노즐 성능을 계산하기 전에 호출되어 연소실 내부의 상태를 정의하는 데 사용될 수 있습니다.
- 계산은 외부 CEA(Chemical Equilibrium with Applications) 라이브러리 호출을 통해 이루어지며, 입력 값의 유효성 검사 및 CEA 호출 오류 처리 로직을 포함합니다.

# Input

| 명칭        | 기호             | 입력 변수         | 비고                                                                 |
| ----------- | -------------- | ------------- | -------------------------------------------------------------------- |
| 연소실 압력   | $P_c$          | `x.comb.P`      | [Pa] (일반적으로 `Comb_Itercalc.m` 등 이전 단계에서 계산된 값)          |
| 혼합비 (O/F) | $\\text{OF}$      | `x.comb.OF`     | - (일반적으로 `Comb_Itercalc.m` 등 이전 단계에서 계산된 값)            |
| 노즐 팽창비  | $\\varepsilon$   | `x.nozzle.eps`  | - (초기 입력 또는 시스템 설정에 따름)                                   |
| CEA 추진제 객체 | -              | `x.cea`         | MATLAB CEA wrapper 객체 (추진제 조합에 대한 정보 포함)                   |

```MATLAB
% 예시 입력값 할당 (실제 사용 시 x 구조체 통해 전달됨)
% Pc = x.comb.P;         % [Pa]
% OF = x.comb.OF;        % dimensionless
% eps = x.nozzle.eps;    % dimensionless
% cea = x.cea;           % CEA object
```

# System
## 1. 입력 변환 및 초기화
- 입력 연소실 압력 $P_c$를 psia 단위로 변환합니다.
- 출력 변수인 분자량 (`mw`), 비열비 (`gamma`), 밀도 (`rho_c`)를 `NaN`으로 초기화합니다.

```MATLAB
Pc_psia = Pc / 6894.757; % psia

% Initialize outputs
mw = NaN;       % Chamber Molecular Weight (kg/kmol)
gamma = NaN;    % Chamber Specific Heat Ratio
rho_c = NaN;    % Chamber Density (kg/m^3)
```

## 2. 입력 유효성 검사
- CEA 계산에 필요한 주요 입력값들 ($P_{c, \text{psia}}$, $\\text{OF}$, $\\varepsilon$, `cea` 객체)이 유효한지 (finite, positive, non-empty 등) 검사합니다.
- 모든 입력이 유효한 경우에만 CEA를 통한 물성치 계산을 진행합니다. 그렇지 않으면 경고를 발생시키고 초기화된 `NaN` 값을 유지합니다.

```MATLAB
% Check if inputs for CEA are valid
% eps (팽창비)는 get_Chamber_MolWt_gamma 및 get_Chamber_Density 함수에서 사용되므로 유효성 검사에 포함합니다.
if isfinite(Pc_psia) && Pc_psia > 0 && isfinite(OF) && OF >= 0 && isfinite(eps) && eps > 0 && ~isempty(cea)
    % ... CEA 계산 로직 ...
else
    warning(\'CombParam:InvalidInputs\', \'Skipping CombParam CEA calculation due to invalid inputs: Pc=%.2f Pa, OF=%.2f, eps=%.1f, cea is empty=%d\', Pc, OF, eps, isempty(cea));
    % mw, gamma, rho_c remain NaN as initialized
end
```

## 3. 연소실 분자량 ($M_w$) 및 비열비 ($\gamma_c$) 계산
- 유효한 입력 조건 하에서 CEA 함수 `get_Chamber_MolWt_gamma`를 호출하여 연소실의 평균 분자량과 비열비를 계산합니다.
- CEA는 분자량을 `lb/lb-mole` (수치적으로 `g/mol` 또는 `kg/kmol`과 동일)로, 비열비는 무차원으로 반환합니다.
- 반환된 값이 유효한지 (finite, positive) 확인한 후 저장합니다.
- CEA 호출 중 오류 발생 시 경고를 표시하고 관련 값은 `NaN`으로 유지됩니다.

```MATLAB
    % --- Calculate Chamber Molecular Weight and Specific Heat Ratio ---
    try
        chamber_props = cea.get_Chamber_MolWt_gamma(pyargs(\'Pc\', Pc_psia, \'MR\', OF, \'eps\', eps));
        mw_lbm_per_lbmole = double(chamber_props{1}); % Original value in lbm/lbmole (effectively kg/kmol)
        gamma_temp_val = double(chamber_props{2});    % dimensionless

        mw_temp = mw_lbm_per_lbmole; % RocketCEA 반환 단위는 lb/lb-mole이며, 이는 kg/kmol과 수치적으로 동일.

        if isfinite(mw_temp) && mw_temp > 0 && isfinite(gamma_temp_val) && gamma_temp_val > 0
            mw = mw_temp; % kg/kmol
            gamma = gamma_temp_val;
        else
            warning(\'CombParam:InvalidCEA_ChamberProps\', ...
                    \'CEA get_Chamber_MolWt_gamma returned non-finite/non-positive mw (%.2f kg/kmol) or gamma (%.2f) for Pc=%.2f, OF=%.2f, eps=%.1f\', ...
                    mw_temp, gamma_temp_val, Pc_psia, OF, eps);
            % mw and gamma remain NaN
        end
    catch ME_ChamberProps
        warning(\'CombParam:CEA_ChamberProps_Error\', ...
                \'Error calling CEA get_Chamber_MolWt_gamma for Pc=%.2f, OF=%.2f, eps=%.1f: %s\', ...
                Pc_psia, OF, eps, ME_ChamberProps.message);
        % mw and gamma remain NaN
    end
```

## 4. 연소실 밀도 ($\rho_c$) 계산
- 유효한 입력 조건 하에서 CEA 함수 `get_Chamber_Density`를 호출하여 연소실 내 연소 가스의 밀도를 계산합니다.
- CEA는 밀도를 `lbm/ft³` 단위로 반환하며, 이를 `kg/m³` 단위로 변환합니다.
  ($1 \text{ lbm/ft}^3 = 16.0184634 \text{ kg/m}^3$)
- 반환된 값이 유효한지 (finite, positive) 확인한 후 저장합니다.
- CEA 호출 중 오류 발생 시 경고를 표시하고 밀도 값은 `NaN`으로 유지됩니다.

```MATLAB
    % --- Calculate Chamber Density ---
    try
        rho_lbm_cuft = cea.get_Chamber_Density(pyargs(\'Pc\', Pc_psia, \'MR\', OF, \'eps\', eps));
        rho_c_temp_unconverted = double(rho_lbm_cuft); % Original value in lbm/ft^3
        
        % Convert rho_c to kg/m^3
        rho_c_temp = rho_c_temp_unconverted * 16.0184634; % kg/m^3

        if isfinite(rho_c_temp) && rho_c_temp > 0
            rho_c = rho_c_temp;
        else
            warning(\'CombParam:InvalidCEA_ChamberDensity\', ...
                    \'CEA get_Chamber_Density returned non-finite/non-positive rho_c (%.2f kg/m^3) for Pc=%.2f, OF=%.2f, eps=%.1f\', ...
                    rho_c_temp, Pc_psia, OF, eps);
            % rho_c remains NaN
        end
    catch ME_ChamberDensity
        warning(\'CombParam:CEA_ChamberDensity_Error\', ...
                \'Error calling CEA get_Chamber_Density for Pc=%.2f, OF=%.2f, eps=%.1f: %s\', ...
                Pc_psia, OF, eps, ME_ChamberDensity.message);
        % rho_c remains NaN
    end
```

# Output

| 명칭        | 기호       | 출력 변수       | 단위    | 비고                          |
| ----------- | ---------- | --------------- | ------- | ----------------------------- |
| 연소실 분자량 | $M_w$      | `x.comb.mw`     | kg/kmol | 연소 생성물의 평균 분자량      |
| 연소실 비열비 | $\\gamma_c$ | `x.comb.gamma`  | -       | 연소 생성물의 비열비 (감마)    |
| 연소실 밀도   | $\\rho_c$   | `x.comb.rho_c`  | kg/m³   | 연소 생성물의 밀도             |

```MATLAB
x.comb.mw = mw;       % Chamber Molecular Weight (kg/kmol)
x.comb.gamma = gamma;   % Chamber Specific Heat Ratio
x.comb.rho_c = rho_c; % Chamber Density (kg/m^3)
```

# 전체 코드
```MATLAB
function [x] = Comb_param(x)
%% Input
% 연소실 압력, O/F비, CEA 객체는 x.comb 또는 x에서, 노즐 팽창비는 x.nozzle에서 가져옵니다.
Pc = x.comb.P;
OF = x.comb.OF;
eps = x.nozzle.eps; % 노즐 팽창비는 노즐 모듈의 파라미터를 사용
cea = x.cea;

%% System
Pc_psia = Pc / 6894.757; % psia

% Initialize outputs
mw = NaN;       % Initialize Chamber Molecular Weight (kg/kmol)
gamma = NaN;    % Initialize Chamber Specific Heat Ratio
rho_c = NaN;    % Initialize Chamber Density (kg/m^3)

% Check if inputs for CEA are valid
% eps (팽창비)는 get_Chamber_MolWt_gamma 및 get_Chamber_Density 함수에서 사용되므로 유효성 검사에 포함합니다.
if isfinite(Pc_psia) && Pc_psia > 0 && isfinite(OF) && OF >= 0 && isfinite(eps) && eps > 0 && ~isempty(cea)
    % --- Calculate Chamber Molecular Weight and Specific Heat Ratio ---
    try
        chamber_props = cea.get_Chamber_MolWt_gamma(pyargs('Pc', Pc_psia, 'MR', OF, 'eps', eps));
        mw_lbm_per_lbmole = double(chamber_props{1}); % Original value in lbm/lbmole (effectively kg/kmol)
        gamma_temp_val = double(chamber_props{2});    % dimensionless

        mw_temp = mw_lbm_per_lbmole; % RocketCEA 반환 단위는 lb/lb-mole이며, 이는 kg/kmol과 수치적으로 동일.

        if isfinite(mw_temp) && mw_temp > 0 && isfinite(gamma_temp_val) && gamma_temp_val > 0
            mw = mw_temp; % kg/kmol
            gamma = gamma_temp_val;
        else
            warning('CombParam:InvalidCEA_ChamberProps', ...
                    'CEA get_Chamber_MolWt_gamma returned non-finite/non-positive mw (%.2f kg/kmol) or gamma (%.2f) for Pc=%.2f, OF=%.2f, eps=%.1f', ...
                    mw_temp, gamma_temp_val, Pc_psia, OF, eps);
            % mw and gamma remain NaN
        end
    catch ME_ChamberProps
        warning('CombParam:CEA_ChamberProps_Error', ...
                'Error calling CEA get_Chamber_MolWt_gamma for Pc=%.2f, OF=%.2f, eps=%.1f: %s', ...
                Pc_psia, OF, eps, ME_ChamberProps.message);
        % mw and gamma remain NaN
    end

    % --- Calculate Chamber Density ---
    try
        % RocketCEA의 get_Chamber_Density는 밀도를 [lbm/ft^3]로 반환
        rho_lbm_cuft = cea.get_Chamber_Density(pyargs('Pc', Pc_psia, 'MR', OF, 'eps', eps));
        rho_c_temp_unconverted = double(rho_lbm_cuft); % Original value in lbm/ft^3
        
        % Convert rho_c to kg/m^3
        % 1 lbm/ft^3 = 16.0184634 kg/m^3
        rho_c_temp = rho_c_temp_unconverted * 16.0184634; % kg/m^3

        if isfinite(rho_c_temp) && rho_c_temp > 0
            rho_c = rho_c_temp;
        else
            warning('CombParam:InvalidCEA_ChamberDensity', ...
                    'CEA get_Chamber_Density returned non-finite/non-positive rho_c (%.2f kg/m^3) for Pc=%.2f, OF=%.2f, eps=%.1f', ...
                    rho_c_temp, Pc_psia, OF, eps);
            % rho_c remains NaN
        end
    catch ME_ChamberDensity
        warning('CombParam:CEA_ChamberDensity_Error', ...
                'Error calling CEA get_Chamber_Density for Pc=%.2f, OF=%.2f, eps=%.1f: %s', ...
                Pc_psia, OF, eps, ME_ChamberDensity.message);
        % rho_c remains NaN
    end
else
    warning('CombParam:InvalidInputs', 'Skipping CombParam CEA calculation due to invalid inputs: Pc=%.2f Pa, OF=%.2f, eps=%.1f, cea is empty=%d', Pc, OF, eps, isempty(cea));
    % mw, gamma, rho_c remain NaN as initialized
end

%% Output
x.comb.mw = mw;       % Chamber Molecular Weight (kg/kmol)
x.comb.gamma = gamma;   % Chamber Specific Heat Ratio
x.comb.rho_c = rho_c; % Chamber Density (kg/m^3)

end
```

</rewritten_file> 