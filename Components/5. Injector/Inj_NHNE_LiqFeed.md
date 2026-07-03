---
tags:
  - 2상유동
  - 인젝터
Author: SRS 33기 박호진
---
# 소개
- `Inj_NHNE_LiqFeed.m`은 **탱크에서 액체 상의 유출이 일어날 때, 두 상(N₂O 액체+증기)이 존재하는 인젝터에서의 유동**을 모사한 함수입니다.
- 해당 모델은 **비균질(Non-Homogeneous) 비평형(Non-Equilibrium) 상태에서의 질량 유동을 CdA 방식과 HEM 방식의 가중 평균**으로 처리합니다.
- NHNE 모델은 액체 체류 시간 척도($\tau_r$)와 버블 성장 시간 척도($\tau_b$)의 비율로 정의되는 비평형 파라미터 $\kappa = \tau_b / \tau_r$를 사용하여 두 모델의 가중치를 동적으로 결정합니다. (Dyer 등의 연구 기반, 상수항 무시 버전 식 (35) 대신 식 (33), (34) 직접 사용)
- 인젝터 입구가 탱크 출구에 바로 연결되어있다는 조건을 적용하였다. (배관 라인 무시)
# Input

| 명칭         | 기호                 | 입력 변수        | 비고                                      |
| ---------- | ------------------ | ------------ | --------------------------------------- |
| 인젝터 상류 압력  | $P_1$              | x.tank.P     | 인젝터 상부 압력                               |
| 인젝터 후단 압력  | $P_2$              | x.comb.Pinj  | 인젝터 하류 압력 (기본). 유효하지 않으면 x.comb.P 사용 |
| 연소실 압력    | $P_c$              | x.comb.P     | 인젝터 하류 압력 (대체)                         |
| 인젝터 상류 밀도  | $\rho_1$           | x.tank.rho_l | 상류 밀도 (탱크 액체 상의 밀도를 취함.)                |
| 인젝터 하류 밀도  | $\rho_2$           | x.inj.rho    | 하류 밀도                                   |
| 인젝터 상류 엔탈피 | $h_1$              | x.tank.h_l   | 상류 엔탈피                                  |
| 인젝터 하류 엔탈피 | $h_2$              | x.inj.h      | 하류 엔탈피                                  |
| 인젝터 면적     | $A_{\text{inj}}$   | x.inj.A      | 인젝터 유효 단면적                              |
| 인젝터 유량계수   | $C_{d,\text{inj}}$ | x.inj.Cd     | 인젝터 유량 계수                               |
| 인젝터 길이     | $L_{\text{inj}}$   | x.inj.L      | 인젝터 채널 길이                               |
| 증기압        | $P_{\nu 1}$        | x.tank.P     | 상류에서의 포화압력<br>(탱크가 과급 상태가 아니면 탱크 압력 이용) |

```matlab
fluid = x.fluid;
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_NHNE_LiqFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_NHNE_LiqFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho1 = x.tank.rho_l;
rho2 = x.inj.rho; % This rho is calculated by InjState_LiqFeed called before this
h1 = x.tank.h_l;
h2 = x.inj.h; % This h is calculated by InjState_LiqFeed called before this

% Saturation pressure at upstream temperature/state
% Approximation: Use tank pressure if not supercharged or subcooled significantly.
% More accurate: Calculate Psat(T_tank) if possible.
Pv1 = x.tank.P; % Approximation - Consider improving if necessary
% Pv1 = x.inj.P; % Approximation - Consider improving if necessary

A_inj = x.inj.A;
Cd_inj = x.inj.Cd;
L_inj = x.inj.L; % 인젝터 길이
```

# System
- 비평형 파라미터 $\kappa$는 버블 성장 시간 척도($\tau_b$)와 액체 체류 시간 척도($\tau_r$)의 비율로 계산됩니다.
$$
\tau_b = \sqrt{\frac{1.5 \cdot \rho_1}{P_{\nu 1} - P_2}}
$$
$$
\tau_r = L_{\text{inj}} \sqrt{\frac{\rho_1}{2 (P_1 - P_2)}}
$$
$$
\kappa = \frac{\tau_b}{\tau_r}
$$

- 일반적인 비압축성 CdA 모델:
  $$
  \dot{m}_{\text{inc}} = C_{d, inj} A_{\text{inj}} \sqrt{2 \rho_1 (P_1 - P_2)}
  $$

- HEM 모델:
  $$
  \dot{m}_{\text{HEM}} = C_{d, inj} A_{\text{inj}} \rho_2 \sqrt{2 (h_1 - h_2)}
  $$

-  NHNE 질량 유량 (수정된 가중치 적용)
$$
\dot{m}_{\text{NHNE}} =  
\left(\frac{\kappa}{1 + \kappa}\right) \cdot \dot{m}_{\text{inc}} + 
\left( \frac{1}{1 + \kappa} \right) \cdot \dot{m}_{\text{HEM}} 
$$

```matlab
deltaP = P1 - P2;
mdot_inc = 0; % Initialize
mdot_HEM = 0; % Initialize
mdot_inj = 0; % Initialize
calculated_kappa = NaN; % kappa 계산 결과 저장 변수
tau_b_val = NaN;        % tau_b 계산 결과 저장 변수
tau_r_val = NaN;        % tau_r 계산 결과 저장 변수

if deltaP > 0
    % tau_b 및 tau_r 계산
    tau_b_calculated_successfully = false;
    % Pv1 - P2 > 0 이어야 tau_b 계산 가능
    if rho1 > 0 && (Pv1 - P2) > 0 
        tau_b_val = sqrt(1.5 * rho1 / (Pv1 - P2));
        tau_b_calculated_successfully = isfinite(tau_b_val);
    else
        warning('Inj_NHNE_LiqFeed:TauBCondition', 'Conditions for tau_b calculation not met (rho1=%.2f, Pv1-P2=%.2f).', rho1, Pv1-P2);
    end
    
    tau_r_calculated_successfully = false;
    % L_inj > 0, rho1 > 0, deltaP > 0 이어야 tau_r 계산 가능
    if L_inj > 0 && rho1 > 0 % deltaP > 0은 외부 if 조건으로 이미 만족
        tau_r_val = L_inj * sqrt(rho1 / (2 * deltaP));
        if isfinite(tau_r_val) && tau_r_val ~= 0
            tau_r_calculated_successfully = true;
        else
            warning('Inj_NHNE_LiqFeed:TauRCalculation', 'tau_r calculation resulted in non-finite or zero value (%.2f).', tau_r_val);
        end
    else
        warning('Inj_NHNE_LiqFeed:TauRCondition', 'Conditions for tau_r calculation not met (L_inj=%.2f, rho1=%.2f).', L_inj, rho1);
    end

    if tau_b_calculated_successfully && tau_r_calculated_successfully
        calculated_kappa = tau_b_val / tau_r_val;
    else
        calculated_kappa = NaN; % 계산 실패 시 NaN
        warning('Inj_NHNE_LiqFeed:KappaPreCalculationFailure', 'Failed to calculate tau_b or tau_r, kappa cannot be determined.');
    end
    
    % 가중치 계산
    if isnan(calculated_kappa)
        warning('Inj_NHNE_LiqFeed:KappaNaN', 'Kappa calculation resulted in NaN. Defaulting to HEM-dominant flow (w_hem=1).');
        w_inc = 0;
        w_hem = 1;
        % calculated_kappa는 NaN으로 유지
    elseif ~isfinite(calculated_kappa) % Inf 또는 -Inf
        if calculated_kappa > 0 % Inf (e.g. tau_r is zero)
            w_inc = 1;
            w_hem = 0;
        else % -Inf (or other non-finite, though kappa should be positive)
            warning('Inj_NHNE_LiqFeed:KappaNonFinite', 'Kappa is non-finite or negative infinite (%f). Defaulting to HEM-dominant flow (w_hem=1).', calculated_kappa);
            w_inc = 0;
            w_hem = 1;
            calculated_kappa = NaN; % 출력 kappa를 NaN으로 설정하여 문제 표시
        end
    else % calculated_kappa is finite and not NaN
        if calculated_kappa < 0
            warning('Inj_NHNE_LiqFeed:KappaNegative', 'Calculated kappa (%f) is negative. This is physically unexpected. Clamping to 0 (HEM-dominant flow).', calculated_kappa);
            calculated_kappa = 0; 
        end
        w_inc = calculated_kappa / (1 + calculated_kappa);
        w_hem = 1 / (1 + calculated_kappa);
    end
    
    % Calculate CdA flow rate term including Cd*A
    mdot_inc = Cd_inj * A_inj * sqrt(2 * rho1 * deltaP);
    
    % Calculate HEM flow rate term including Cd*A
    if h1 >= h2
        mdot_HEM_sqrt_part = sqrt(2 * (h1 - h2));
    else
        warning('Inj_NHNE_LiqFeed:NegativeEnthalpyDrop', 'h1 (%.2f J/kg) < h2 (%.2f J/kg) for HEM calculation. Setting mdot_HEM sqrt part to 0.', h1, h2);
        mdot_HEM_sqrt_part = 0;
    end
    mdot_HEM = Cd_inj * A_inj * rho2 * mdot_HEM_sqrt_part;
    
    % Calculate final NHNE mass flow rate using weighted components
    mdot_inj = w_inc * mdot_inc + w_hem * mdot_HEM;
    
else
    % deltaP <= 0, no flow
    mdot_inj = 0;
    calculated_kappa = NaN; % kappa는 정의되지 않음
    mdot_inc = 0;
    mdot_HEM = 0;
    % tau_b_val, tau_r_val은 초기값 NaN 유지
end
```

# Output

| 명칭                | 기호                     | 출력 변수          | 비고                          |
| ------------------- | ---------------------- | -------------- | ----------------------------- |
| 비평형 파라미터         | $\kappa$               | x.inj.kappa    | $\tau_b / \tau_r$로 계산됨         |
| 버블 성장 시간 척도     | $\tau_b$              | x.inj.tau_b    | Characteristic bubble growth time |
| 액체 체류 시간 척도     | $\tau_r$              | x.inj.tau_r    | Liquid residence time         |
| inc 질량 유량 (Cd*A 포함) | $\dot{m}_{inc}$        | x.inj.mdot_inc |                               |
| HEM 질량 유량 (Cd*A 포함) | $\dot{m}_{HEM}$        | x.inj.mdot_HEM |                               |
| NHNE 질량 유량        | $\dot{m}_{\text{inj}}$ | x.inj.mdot     | NHNE 기반 유량                  |


```matlab
x.inj.kappa = calculated_kappa;
x.inj.tau_b = tau_b_val;
x.inj.tau_r = tau_r_val;
% Output the component mass flow rates *including* Cd*A
x.inj.mdot_inc = mdot_inc; 
x.inj.mdot_HEM = mdot_HEM; 
% Output the total calculated mass flow rate
x.inj.mdot = mdot_inj;
```

# 전체 코드
```matlab
function [x] = Inj_NHNE_LiqFeed(x)
%% Input
fluid = x.fluid;
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_NHNE_LiqFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_NHNE_LiqFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho1 = x.tank.rho_l;
rho2 = x.inj.rho; % This rho is calculated by InjState_LiqFeed called before this
h1 = x.tank.h_l;
h2 = x.inj.h; % This h is calculated by InjState_LiqFeed called before this

% Saturation pressure at upstream temperature/state
% Approximation: Use tank pressure if not supercharged or subcooled significantly.
% More accurate: Calculate Psat(T_tank) if possible.
Pv1 = x.tank.P; % Approximation - Consider improving if necessary
% Pv1 = x.inj.P; % Approximation - Consider improving if necessary

A_inj = x.inj.A;
Cd_inj = x.inj.Cd;
L_inj = x.inj.L; % 인젝터 길이

%% System
deltaP = P1 - P2;
mdot_inc = 0; % Initialize
mdot_HEM = 0; % Initialize
mdot_inj = 0; % Initialize
calculated_kappa = NaN; % kappa 계산 결과 저장 변수
tau_b_val = NaN;        % tau_b 계산 결과 저장 변수
tau_r_val = NaN;        % tau_r 계산 결과 저장 변수

if deltaP > 0
    % tau_b 및 tau_r 계산
    tau_b_calculated_successfully = false;
    % Pv1 - P2 > 0 이어야 tau_b 계산 가능
    if rho1 > 0 && (Pv1 - P2) > 0 
        tau_b_val = sqrt(1.5 * rho1 / (Pv1 - P2));
        tau_b_calculated_successfully = isfinite(tau_b_val);
    else
        warning('Inj_NHNE_LiqFeed:TauBCondition', 'Conditions for tau_b calculation not met (rho1=%.2f, Pv1-P2=%.2f).', rho1, Pv1-P2);
    end
    
    tau_r_calculated_successfully = false;
    % L_inj > 0, rho1 > 0, deltaP > 0 이어야 tau_r 계산 가능
    if L_inj > 0 && rho1 > 0 % deltaP > 0은 외부 if 조건으로 이미 만족
        tau_r_val = L_inj * sqrt(rho1 / (2 * deltaP));
        if isfinite(tau_r_val) && tau_r_val ~= 0
            tau_r_calculated_successfully = true;
        else
            warning('Inj_NHNE_LiqFeed:TauRCalculation', 'tau_r calculation resulted in non-finite or zero value (%.2f).', tau_r_val);
        end
    else
        warning('Inj_NHNE_LiqFeed:TauRCondition', 'Conditions for tau_r calculation not met (L_inj=%.2f, rho1=%.2f).', L_inj, rho1);
    end

    if tau_b_calculated_successfully && tau_r_calculated_successfully
        calculated_kappa = tau_b_val / tau_r_val;
    else
        calculated_kappa = NaN; % 계산 실패 시 NaN
        warning('Inj_NHNE_LiqFeed:KappaPreCalculationFailure', 'Failed to calculate tau_b or tau_r, kappa cannot be determined.');
    end
    
    % 가중치 계산
    if isnan(calculated_kappa)
        warning('Inj_NHNE_LiqFeed:KappaNaN', 'Kappa calculation resulted in NaN. Defaulting to HEM-dominant flow (w_hem=1).');
        w_inc = 0;
        w_hem = 1;
        % calculated_kappa는 NaN으로 유지
    elseif ~isfinite(calculated_kappa) % Inf 또는 -Inf
        if calculated_kappa > 0 % Inf (e.g. tau_r is zero)
            w_inc = 1;
            w_hem = 0;
        else % -Inf (or other non-finite, though kappa should be positive)
            warning('Inj_NHNE_LiqFeed:KappaNonFinite', 'Kappa is non-finite or negative infinite (%f). Defaulting to HEM-dominant flow (w_hem=1).', calculated_kappa);
            w_inc = 0;
            w_hem = 1;
            calculated_kappa = NaN; % 출력 kappa를 NaN으로 설정하여 문제 표시
        end
    else % calculated_kappa is finite and not NaN
        if calculated_kappa < 0
            warning('Inj_NHNE_LiqFeed:KappaNegative', 'Calculated kappa (%f) is negative. This is physically unexpected. Clamping to 0 (HEM-dominant flow).', calculated_kappa);
            calculated_kappa = 0; 
        end
        w_inc = calculated_kappa / (1 + calculated_kappa);
        w_hem = 1 / (1 + calculated_kappa);
    end
    
    % Calculate CdA flow rate term including Cd*A
    mdot_inc = Cd_inj * A_inj * sqrt(2 * rho1 * deltaP);
    
    % Calculate HEM flow rate term including Cd*A
    if h1 >= h2
        mdot_HEM_sqrt_part = sqrt(2 * (h1 - h2));
    else
        warning('Inj_NHNE_LiqFeed:NegativeEnthalpyDrop', 'h1 (%.2f J/kg) < h2 (%.2f J/kg) for HEM calculation. Setting mdot_HEM sqrt part to 0.', h1, h2);
        mdot_HEM_sqrt_part = 0;
    end
    mdot_HEM = Cd_inj * A_inj * rho2 * mdot_HEM_sqrt_part;
    
    % Calculate final NHNE mass flow rate using weighted components
    mdot_inj = w_inc * mdot_inc + w_hem * mdot_HEM;
    
else
    % deltaP <= 0, no flow
    mdot_inj = 0;
    calculated_kappa = NaN; % kappa는 정의되지 않음
    mdot_inc = 0;
    mdot_HEM = 0;
    % tau_b_val, tau_r_val은 초기값 NaN 유지
end

%% Output
x.inj.kappa = calculated_kappa;
x.inj.tau_b = tau_b_val;
x.inj.tau_r = tau_r_val;
% Output the component mass flow rates *including* Cd*A
x.inj.mdot_inc = mdot_inc; 
x.inj.mdot_HEM = mdot_HEM; 
% Output the total calculated mass flow rate
x.inj.mdot = mdot_inj;

end
```