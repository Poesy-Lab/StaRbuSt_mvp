---
tags:
  - 연소실
  - 특성속도
  - 연소압
  - 반복 계산
  - 준정상상태
Author: SRS 33기 박호진
---
# 소개
- `Comb_Itercalc.m`은 **입력된 추진제 유량과 입력 연소압을 기반으로 특성 속도($c^*$) 및 연소 온도($T_c$), 그리고 해당 반복 스텝에서의 새로운 연소압($p_{c, \text{calc}}$)을 계산**하는 함수입니다. 이 함수 자체는 특정 시점의 상태에 대한 계산을 수행합니다.
- 특성속도 효율($\eta_{c^*}$)은 $c^*$ 계산에 직접 반영되지는 않지만, 최종 연소압 계산 시 사용됩니다.
- **중요 (사용 맥락 및 준정상상태 가정):** 이 함수는 주로 `LiqFeed.m` 또는 `VapFeed.m`과 같은 **외부 반복 루프 내에서 호출**되어, 해당 시간 스텝에서의 **준정상상태(quasi-steady-state) 연소압**을 찾는 데 사용됩니다. 외부 루프는 다음 과정을 통해 평형점을 찾습니다:
    1.  현재 연소압 추정치($p_{c, \text{in}}$)로 공급 유량($\dot{m}_{ox}, \dot{m}_f$)을 계산합니다.
    2.  `Comb_Itercalc.m`은 이 공급 유량($\dot{m}_p$)과 $p_{c, \text{in}}$을 사용하여 $c^*$를 계산하고, "이 유량이 나갈 때 필요한 압력"($p_{c, \text{calc}}$)을 예측합니다.
    3.  외부 루프는 $p_{c, \text{calc}}$와 $p_{c, \text{in}}$이 수렴할 때까지 $p_{c, \text{in}}$과 그에 따른 공급 유량을 업데이트하며 반복합니다.
    4.  수렴 시, 최종 $p_c$는 해당 시간 스텝에서 공급 유량과 노즐 질식 유량이 균형을 이루는 ($\dot{m}_p \approx \dot{m}_{\text{choked}} = \frac{p_c A_t}{\eta_{c^*} c^*}$) 준정상상태 압력을 나타냅니다.
- **장점:**
    *   **전체 성능 예측에 적합:** 이 준정상상태 접근법은 전체 연소 시간에 걸친 연소압 및 추력의 **전반적인 변화 추세**를 예측하는 데 효과적입니다.
    *   **시스템 변화 반영:** 탱크 압력 강하, 연료 그레인 후퇴 등 시간에 따라 천천히 변하는 시스템 상태가 연소 성능에 미치는 영향을 모사할 수 있습니다.
    *   **구현 및 계산 효율성:** 완전한 동적 모델($dp_c/dt$)보다 구현이 상대적으로 간단하고 계산 비용이 낮습니다.
- **한계점:**
    *   **빠른 동적 현상 모사 불가:** 각 시간 스텝 내에서 압력이 매우 빠르게 평형에 도달한다고 가정하므로, 점화/소화 과도 현상이나 연소 불안정과 같은 **매우 짧은 시간 동안의 급격한 압력 변화**는 정확하게 모사하기 어렵습니다.
    *   **동적 효과 미반영:** 연소실 내 질량 축적/방출 효과나 온도/체적의 빠른 변화율($\dot{T}_c, \dot{V}_c$)이 압력 변화에 미치는 직접적인 동적 영향은 고려되지 않습니다.
- 연료 질량 유량(`x.fuel.mdot`)은 이 함수 호출 전에 외부에서 계산되어 입력으로 제공되어야 합니다.

# Input

| 명칭            | 기호             | 입력 변수         | 비고                                                                 |
| ------------- | -------------- | ------------- | -------------------------------------------------------------------- |
| 인젝터 분사 질량유량 | $\dot{m}_{ox}$ | x.inj.mdot    | [kg/s]                                                               |
| 연료 질량유량      | $\dot{m}_f$    | x.fuel.mdot   | [kg/s] (**외부에서 사전 계산됨**)                                        |
| 연소실 압력 (입력) | $p_{c, \text{in}}$ | x.comb.P      | [Pa] (**이전 스텝의 결과 또는 초기 추정치**)                             |
| CEA 추진제 객체    | -              | x.cea         | 추진제 조합에 대한 CEA 객체                                                |
| 특성속도 효율       | $\eta_{c^*}$   | x.comb.eta    | 0~1 (최종 연소압 계산 시 사용)                                        |
| 노즐 목 면적       | $A_t$          | x.nozzle.At   | [m²]                                                                 |
| 연소실 반경        | $R_c$          | x.comb.R_comb | [m] (인젝터 후단 압력 $P_{inj}$ 계산 시 필요)                               |

```MATLAB
mdot_ox = x.inj.mdot;
mdot_f = x.fuel.mdot; % Pre-calculated by caller
Pc_input = x.comb.P; % Input Pc (previous iteration/initial guess)
cea = x.cea;
eta_cstar = x.comb.eta;
At = x.nozzle.At;
% R_comb = x.comb.R_comb; % Pinj 계산 시 필요
```

# System
## 1. 연소실 질량 유량 계산
- 1.1 추진제 질량 유량 계산
$$ 
\dot{m}_{p} = \dot{m}_f + \dot{m}_{ox} 
$$ 
```MATLAB
mdot_p = mdot_f + mdot_ox;
```

- 1.2 OF비 계산
$$ 
\text{OF} = \frac{\dot{m}_{ox}}{\dot{m}_f} 
$$ 
> **참고:** $\dot{m}_f$ 또는 $\dot{m}_{ox}$ 가 유효하지 않거나 $\dot{m}_f$ 가 0에 매우 가까운 경우, OF는 NaN 또는 Inf로 설정될 수 있습니다.

```MATLAB
% Calculate O/F Ratio (Simplified Logic)
OF = NaN; % Initialize OF
if isfinite(mdot_ox) && isfinite(mdot_f)
    if mdot_f > 1e-12 % Use tolerance instead of exact zero comparison
        OF = mdot_ox / mdot_f;
    elseif abs(mdot_f) <= 1e-12 % mdot_f is effectively zero
        if mdot_ox > 1e-12
            OF = Inf;
        else % Both mdot_f and mdot_ox are effectively zero
            OF = 0;
        end
    end % No explicit warning for mdot_f < 0, assume handled by isfinite
else
    warning('Comb:InvalidMassFlows', 'Cannot calculate OF due to non-finite mdot_ox (%.2f) or mdot_f (%.2f).', mdot_ox, mdot_f);
    % OF remains NaN
end
```

## 2. 특성 속도, 연소 온도 및 연소압 계산
- 2.1 입력 연소압 $p_{c, \text{in}}$ 및 OF 비 유효성 검사
```MATLAB
Pc_psia = Pc_input / 6894.76; % psia
cstar = NaN; % Initialize cstar
Tc_K = NaN; % Initialize combustion temperature

if isfinite(OF) && OF >= 0 && isfinite(Pc_psia) && Pc_psia > 0
    % Proceed with CEA calculation only if inputs are valid
    % ... CEA calculation code ...
else
    warning('Comb:InvalidCEAInput', 'Skipping CEA c* and Tcomb calculation due to invalid OF (%.2f) or Pc_psia (%.2f).', OF, Pc_psia);
    cstar = NaN;
    Tc_K = NaN;
end
```

- 2.2 특성속도 계산 ($p_{c, \text{in}}$, $\text{OF}$ 기준)
$$
c^* = c^*_{\text{CEA}}(p_{c, \text{in}}, \text{OF})
$$
> **오류 처리:** CEA 계산 중 오류가 발생하거나 결과가 유효하지 않으면 $c^*$ 는 NaN으로 설정됩니다.

```MATLAB
    try
        cstar_ft = cea.get_Cstar(pyargs('Pc', Pc_psia, 'MR', OF)); % ft/s
        cstar = double(cstar_ft * 0.3048); % m/s

        % Check if CEA output is valid
        if ~isfinite(cstar) || cstar <= 0
             warning('Comb:InvalidCEAOutput', 'CEA returned non-positive or non-finite c* (%.2f) for Pc=%.2f, OF=%.2f', cstar, Pc_psia, OF);
             cstar = NaN; % Ensure cstar is NaN if CEA output is invalid
        end
    catch ME
        warning('Comb:CEAError', 'CEA c* calculation failed for Pc=%.2f psia, OF=%.2f: %s', Pc_psia, OF, ME.message);
        cstar = NaN; % Ensure cstar is NaN on error
    end
```

- 2.3 연소 온도 계산 ($p_{c, \text{in}}$, $\text{OF}$ 기준)
$$
T_c = T_{c, \text{CEA}}(p_{c, \text{in}}, \text{OF})
$$
> **오류 처리:** CEA 계산 중 오류가 발생하거나 결과가 유효하지 않으면 $T_c$ 는 NaN으로 설정됩니다.

```MATLAB
        if isfinite(cstar) % Attempt Tcomb only if cstar calculation was tried (and inputs were valid)
            try
                Tc_R = cea.get_Tcomb(pyargs('Pc', Pc_psia, 'MR', OF)); % Get Tcomb in Rankine
                Tc_K_temp = double(Tc_R) * (5/9); % Convert to Kelvin

                % Check if CEA Tcomb output is valid
                if isfinite(Tc_K_temp) && Tc_K_temp > 0
                    Tc_K = Tc_K_temp;
                else
                    warning('Comb:InvalidCEA_Tcomb', 'CEA returned non-positive or non-finite Tcomb (%.2f K) for Pc=%.2f, OF=%.2f', Tc_K_temp, Pc_psia, OF);
                    Tc_K = NaN;
                end
            catch ME_Tcomb
                warning('Comb:CEA_Tcomb_Error', 'CEA Tcomb calculation failed for Pc=%.2f psia, OF=%.2f: %s', Pc_psia, OF, ME_Tcomb.message);
                Tc_K = NaN; % Ensure Tc_K is NaN on error
            end
        end
```

- 2.4 **새로운 연소압 계산** (해당 스텝의 결과)
> **이론적 배경 (준정상상태):** 외부 루프가 수렴하는 준정상상태에서는 연소실 압력($p_c$)과 노즐 목에서의 질식 유량($\dot{m}_{\text{choked}}$), 특성 속도($c^*$), 노즐 목 면적($A_t$) 사이에 다음과 같은 관계가 성립합니다 (효율 $\eta_{c^*}$ 고려):
> $$ p_c = \frac{\eta_{c^*} \cdot c^* \cdot \dot{m}_{\text{choked}}}{A_t} $$
> 
> **코드 구현 (반복 계산의 한 단계):** `Comb_Itercalc.m` 함수는 이 준정상상태 자체를 찾는 것이 아니라, **외부 루프의 반복 계산 과정에 필요한 예측값을 제공**하는 역할을 합니다. 즉, **입력된 총 추진제 유량($\dot{m}_p = \dot{m}_f + \dot{m}_{ox}$)** 과 **입력 압력 $p_{c, \text{in}}$ 기준**으로 계산된 $c^*$를 사용하여, **"만약 현재 공급되는 유량 $\dot{m}_p$가 실제로 노즐을 통해 나간다면 연소압은 얼마가 될 것인가?"** 를 예측($p_{c, \text{calc}}$)하여 외부 루프에 반환합니다. 이 피드백을 통해 외부 루프가 준정상상태 $p_c$로 수렴하게 됩니다.

$$ 
p_{c, \text{calc}} = \frac{\eta_{c^*} \cdot c^* \cdot \dot{m}_p}{A_t} 
$$ 
> **참고:** 계산된 $c^*$가 유효하지 않으면 $p_{c, \text{calc}}$ 는 NaN으로 설정됩니다.

```MATLAB
Pc_calc = NaN; % Initialize calculated Pc
if isfinite(cstar) && cstar > 0 % Also check if cstar is positive
    Pc_calc = ( eta_cstar * cstar * mdot_p ) / At; % Pa
else
    Pc_calc = NaN; % Ensure Pc_calc is NaN if cstar is not valid
end

% --- 인젝터 압력 (Pinj) 계산 --- (추가된 부분)
% 연소실 단면적 Ac 및 수축비 fac_CR 계산
% Pinj = Pinj_ov_Pcomb * Pc_calc (CEA 함수 get_Pinj_over_Pcomb 사용)
% 유효성 검사 및 오류 처리 포함

Ac = pi * (x.comb.R_comb^2); % 연소실 단면적 (m^2)
fac_CR = Ac / At; % 수축비 (Contraction Ratio)

Pc_calc_psia = Pc_calc / 6894.757; % Pc_calc를 psia로 변환
Pinj = NaN; % Initialize Injector Pressure

if isfield(x, 'comb') && isfield(x.comb, 'R_comb') && isfinite(x.comb.R_comb) && x.comb.R_comb > 0 && ...
   isfinite(At) && At > 0 && isfinite(Pc_calc) && Pc_calc > 0 && isfinite(OF) && OF >= 0 && ~isempty(cea)
    try
        Pinj_ov_Pcomb_result = cea.get_Pinj_over_Pcomb(pyargs('Pc', Pc_calc_psia, 'MR', OF, 'fac_CR', fac_CR));
        Pinj_ov_Pcomb = double(Pinj_ov_Pcomb_result);

        if isfinite(Pinj_ov_Pcomb) && Pinj_ov_Pcomb > 0
            Pinj = Pinj_ov_Pcomb * Pc_calc; % Pa
        else
            warning('Comb:InvalidCEA_PinjRatio', 'CEA get_Pinj_over_Pcomb returned non-finite or non-positive ratio (%.4f) for Pc=%.2f psia, OF=%.2f, fac_CR=%.2f', Pinj_ov_Pcomb, Pc_calc_psia, OF, fac_CR);
            Pinj = NaN;
        end
    catch ME_Pinj
        warning('Comb:CEA_PinjError', 'CEA get_Pinj_over_Pcomb calculation failed for Pc=%.2f psia, OF=%.2f, fac_CR=%.2f: %s', Pc_calc_psia, OF, fac_CR, ME_Pinj.message);
        Pinj = NaN;
    end
else
    % Detailed warnings for missing inputs to Pinj calculation
    if ~(isfield(x, 'comb') && isfield(x.comb, 'R_comb') && isfinite(x.comb.R_comb) && x.comb.R_comb > 0)
        warning('Comb:InvalidRcomb', 'Skipping Pinj calculation: 연소실 반경 (x.comb.R_comb)이 유효하지 않습니다.');
    elseif ~(isfinite(At) && At > 0)
        warning('Comb:InvalidAt', 'Skipping Pinj calculation: 노즐 목 면적 (At)이 유효하지 않습니다.');
    elseif ~(isfinite(Pc_calc) && Pc_calc > 0)
        warning('Comb:InvalidPcForPinj', 'Skipping Pinj calculation: 계산된 연소실 압력 (Pc_calc)이 유효하지 않습니다.');
    elseif ~(isfinite(OF) && OF >= 0)
        warning('Comb:InvalidOFForPinj', 'Skipping Pinj calculation: 계산된 O/F 비율 (OF)이 유효하지 않습니다.');
    elseif isempty(cea)
        warning('Comb:MissingCEAForPinj', 'Skipping Pinj calculation: CEA 객체가 없습니다.');
    end
end
% --- End Injector Pressure Calculation ---

```

# Output

| 명칭            | 기호                     | 출력 변수         | 비고                                           |
| ------------- | ---------------------- | ------------- | -------------------------------------------- |
| 추진제 질량유량      | $\dot{m}_p$            | x.comb.mdot   | [kg/s] (입력 $\dot{m}_f$ + $\dot{m}_{ox}$)     |
| OF비           | $\text{OF}$            | x.comb.OF     | -                                            |
| 특성속도          | $c^*$                  | x.comb.cstar  | [m/s] (입력 $p_{c, \text{in}}$ 기준)             |
| **연소압 (계산값)** | $p_{c, \text{calc}}$   | **x.comb.P**  | [Pa] (**이번 스텝에서 계산된 새로운 압력**, 외부 루프에서 수렴 필요) |
| 연소 온도         | $T_c$                  | x.comb.T      | [K] (입력 $p_{c, \text{in}}$ 기준)               |
| 수축비           | $\text{fac}_\text{CR}$ | x.comb.fac_CR | - (연소실 단면적 / 노즐 목 면적)                        |
| 인젝터 후단 압력     | $P_{inj}$              | x.comb.Pinj   | [Pa] (계산된 연소압 및 수축비 기반)                      |

```MATLAB
x.comb.mdot = mdot_p;
x.comb.OF = OF;
x.comb.cstar = cstar;
x.comb.P = Pc_calc; % Output the NEWLY CALCULATED Pc for this iteration
x.comb.T = Tc_K; % <<< Add calculated combustion temperature
x.comb.fac_CR = fac_CR; % Add calculated contraction ratio
x.comb.Pinj = Pinj;     % Add calculated injector pressure
```

# 전체 코드
```MATLAB
function [x] = Comb_Itercalc(x)
%% Combustion Chamber Calculations
% Calculates combustor properties, including a NEW combustion pressure (Pc)
% based on the input state (including the Pc from the previous iteration or initial guess).
% Assumes fuel mass flow rate (x.fuel.mdot) has already been calculated.

%% Input
mdot_ox = x.inj.mdot;
mdot_f = x.fuel.mdot; % PRE-CALCULATED by caller
Pc_input = x.comb.P; % Input Pc (previous iteration/initial guess)
cea = x.cea;
eta_cstar = x.comb.eta;
At = x.nozzle.At;
% R_comb = x.comb.R_comb; % Pinj 계산 시 필요

%% System
% Combustion Chamber Mass Flow Rate
mdot_p = mdot_f + mdot_ox;

% Calculate O/F Ratio (Simplified Logic)
OF = NaN; % Initialize OF
if isfinite(mdot_ox) && isfinite(mdot_f)
    if mdot_f > 1e-12 % Use tolerance instead of exact zero comparison
        OF = mdot_ox / mdot_f;
    elseif abs(mdot_f) <= 1e-12 % mdot_f is effectively zero
        if mdot_ox > 1e-12
            OF = Inf;
        else % Both mdot_f and mdot_ox are effectively zero
            OF = 0;
        end
    end % No explicit warning for mdot_f < 0, assume handled by isfinite
else
    warning('Comb:InvalidMassFlows', 'Cannot calculate OF due to non-finite mdot_ox (%.2f) or mdot_f (%.2f).', mdot_ox, mdot_f);
    % OF remains NaN
end

% Characteristic Velocity Calculation based on INPUT Pc
Pc_psia = Pc_input / 6894.76; % psia
cstar = NaN; % Initialize cstar
Tc_K = NaN; % Initialize combustion temperature in Kelvin

% Check if Inputs for CEA (Pc_psia, OF) are valid before calling CEA
if isfinite(OF) && OF >= 0 && isfinite(Pc_psia) && Pc_psia > 0
    try
        cstar_ft = cea.get_Cstar(pyargs('Pc', Pc_psia, 'MR', OF)); % ft/s
        cstar = double(cstar_ft * 0.3048); % m/s

        % Check if CEA output is valid
        if ~isfinite(cstar) || cstar <= 0
             warning('Comb:InvalidCEAOutput', 'CEA returned non-positive or non-finite c* (%.2f) for Pc=%.2f, OF=%.2f', cstar, Pc_psia, OF);
             cstar = NaN; % Ensure cstar is NaN if CEA output is invalid
        end

        % --- Add Combustion Temperature Calculation ---
        if isfinite(cstar) % Attempt Tcomb only if cstar calculation was tried (and inputs were valid)
            try
                Tc_R = cea.get_Tcomb(pyargs('Pc', Pc_psia, 'MR', OF)); % Get Tcomb in Rankine
                Tc_K_temp = double(Tc_R) * (5/9); % Convert to Kelvin

                % Check if CEA Tcomb output is valid
                if isfinite(Tc_K_temp) && Tc_K_temp > 0
                    Tc_K = Tc_K_temp;
                else
                    warning('Comb:InvalidCEA_Tcomb', 'CEA returned non-positive or non-finite Tcomb (%.2f K) for Pc=%.2f, OF=%.2f', Tc_K_temp, Pc_psia, OF);
                    Tc_K = NaN;
                end
            catch ME_Tcomb
                warning('Comb:CEA_Tcomb_Error', 'CEA Tcomb calculation failed for Pc=%.2f psia, OF=%.2f: %s', Pc_psia, OF, ME_Tcomb.message);
                Tc_K = NaN; % Ensure Tc_K is NaN on error
            end
        end
        % --- End Combustion Temperature Calculation ---

    catch ME
        warning('Comb:CEAError', 'CEA c* calculation failed for Pc=%.2f psia, OF=%.2f: %s', Pc_psia, OF, ME.message);
        cstar = NaN; % Ensure cstar is NaN on error
    end
else
    warning('Comb:InvalidCEAInput', 'Skipping CEA c* and Tcomb calculation due to invalid OF (%.2f) or Pc_psia (%.2f).', OF, Pc_psia);
    cstar = NaN;
    Tc_K = NaN; % Also set Tc_K to NaN here
end

% Calculate NEW Combustion Pressure based on calculated cstar
Pc_calc = NaN; % Initialize calculated Pc
if isfinite(cstar) && cstar > 0 % Also check if cstar is positive
    Pc_calc = ( eta_cstar * cstar * mdot_p ) / At; % Pa
else
    Pc_calc = NaN; % Ensure Pc_calc is NaN if cstar is not valid
end

% --- 인젝터 압력 (Pinj) 계산 --- (추가된 부분)
% 연소실 단면적 Ac 및 수축비 fac_CR 계산
% Pinj = Pinj_ov_Pcomb * Pc_calc (CEA 함수 get_Pinj_over_Pcomb 사용)
% 유효성 검사 및 오류 처리 포함

Ac = pi * (x.comb.R_comb^2); % 연소실 단면적 (m^2)
fac_CR = Ac / At; % 수축비 (Contraction Ratio)

Pc_calc_psia = Pc_calc / 6894.757; % Pc_calc를 psia로 변환
Pinj = NaN; % Initialize Injector Pressure

if isfield(x, 'comb') && isfield(x.comb, 'R_comb') && isfinite(x.comb.R_comb) && x.comb.R_comb > 0 && ...
   isfinite(At) && At > 0 && isfinite(Pc_calc) && Pc_calc > 0 && isfinite(OF) && OF >= 0 && ~isempty(cea)
    try
        Pinj_ov_Pcomb_result = cea.get_Pinj_over_Pcomb(pyargs('Pc', Pc_calc_psia, 'MR', OF, 'fac_CR', fac_CR));
        Pinj_ov_Pcomb = double(Pinj_ov_Pcomb_result);

        if isfinite(Pinj_ov_Pcomb) && Pinj_ov_Pcomb > 0
            Pinj = Pinj_ov_Pcomb * Pc_calc; % Pa
        else
            warning('Comb:InvalidCEA_PinjRatio', 'CEA get_Pinj_over_Pcomb returned non-finite or non-positive ratio (%.4f) for Pc=%.2f psia, OF=%.2f, fac_CR=%.2f', Pinj_ov_Pcomb, Pc_calc_psia, OF, fac_CR);
            Pinj = NaN;
        end
    catch ME_Pinj
        warning('Comb:CEA_PinjError', 'CEA get_Pinj_over_Pcomb calculation failed for Pc=%.2f psia, OF=%.2f, fac_CR=%.2f: %s', Pc_calc_psia, OF, fac_CR, ME_Pinj.message);
        Pinj = NaN;
    end
else
    % Detailed warnings for missing inputs to Pinj calculation
    if ~(isfield(x, 'comb') && isfield(x.comb, 'R_comb') && isfinite(x.comb.R_comb) && x.comb.R_comb > 0)
        warning('Comb:InvalidRcomb', 'Skipping Pinj calculation: 연소실 반경 (x.comb.R_comb)이 유효하지 않습니다.');
    elseif ~(isfinite(At) && At > 0)
        warning('Comb:InvalidAt', 'Skipping Pinj calculation: 노즐 목 면적 (At)이 유효하지 않습니다.');
    elseif ~(isfinite(Pc_calc) && Pc_calc > 0)
        warning('Comb:InvalidPcForPinj', 'Skipping Pinj calculation: 계산된 연소실 압력 (Pc_calc)이 유효하지 않습니다.');
    elseif ~(isfinite(OF) && OF >= 0)
        warning('Comb:InvalidOFForPinj', 'Skipping Pinj calculation: 계산된 O/F 비율 (OF)이 유효하지 않습니다.');
    elseif isempty(cea)
        warning('Comb:MissingCEAForPinj', 'Skipping Pinj calculation: CEA 객체가 없습니다.');
    end
end
% --- End Injector Pressure Calculation ---

%% Output
x.comb.mdot = mdot_p;
x.comb.OF = OF;
x.comb.cstar = cstar;
x.comb.P = Pc_calc; % Output the NEWLY CALCULATED Pc for this iteration
x.comb.T = Tc_K; % <<< Add calculated combustion temperature
x.comb.fac_CR = fac_CR; % Add calculated contraction ratio
x.comb.Pinj = Pinj;     % Add calculated injector pressure

end
```