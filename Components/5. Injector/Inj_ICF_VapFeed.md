---
tags:
  - 인젝터
  - 2상유동
  - ChokedFlow
Author: SRS 33기 박호진
---
# 소개
- `Inj_ICF_VapFeed.m`은 **탱크 상단 출구에서 증기상의 유출이 일어날 때, 인젝터에서 유체의 유출**이 일어나는 과정의 시스템을 모사한 함수이다.
- 인젝터를 통한 열전달은 고려되지 않았다.
- 인젝터 질량 유량 공식은 ICF(Isentropic Choked Flow)모델을 이용한다.
- 유량은 압력비에 따라 초크 유동(Choked Flow) 또는 비초크 유동(Non-choked Flow)으로 나뉘어 계산된다.
- 인젝터 입구가 탱크 출구에 바로 연결되어있다는 조건을 적용하였다. (배관 라인 무시)
# Input

| 명칭              | 기호                  | 입력 변수        | 비고        |
| --------------- | ------------------- | ------------ | --------- |
| 탱크 내부 압력        | $P_1$               | x.tank.P     | 인젝터 상류 압력 |
| 인젝터 후단 압력      | $P_2$               | x.comb.Pinj  | 인젝터 하류 압력 (기본). 유효하지 않으면 x.comb.P 사용 |
| 연소실 압력          | $P_c$               | x.comb.P     | 인젝터 하류 압력 (대체) |
| 탱크 내부 증기상 유체 밀도 | $\rho_v$            | x.tank.rho_v |           |
| 탱크 내부 증기상 정압 비열 | $c_{p,v}$           | x.tank.cp_v  |           |
| 탱크 내부 증기상 정적 비열 | $c_{v,v}$           | x.tank.cv_v  |           |
| 인젝터 출구 면적       | $A_{\text{inj}}$    | x.inj.A      |           |
| 인젝터 유량 계수       | $C_{d, \text{inj}}$ | x.inj.Cd     |           |

```MATLAB
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_ICF_VapFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_ICF_VapFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho_v = x.tank.rho_v;
cpv = x.tank.cp_v;
cvv = x.tank.cv_v;
A_inj = x.inj.A;
Cd_inj = x.inj.Cd;

gamma = cpv / cvv; % 비열비 계산
```

# System
- 인젝터로 유출되는 흐름이 초크 유동인지 판별해야 함. 아래 조건을 만족하면 초크 유동임. (여기서 $P_1$은 상류, $P_2$는 하류 압력)
$$
\frac{P_2}{P_1} \le \left( \frac{2}{\gamma + 1} \right)^{\frac{\gamma}{\gamma - 1}}
$$

- 초크 유동일 시, 인젝터로 유출된 질량 유량은 다음과 같음.
$$
\dot{m}_{\text{inj}} =  C_{d,\text{inj}} \cdot A_{\text{inj}} \cdot \sqrt{ \gamma \cdot \rho_v \cdot P_1 \cdot \left( \frac{2}{\gamma + 1} \right)^{\frac{\gamma + 1}{\gamma - 1}} }
$$

- 비초크 유동일 시, 인젝터로 유출된 질량 유량은 다음과 같음.
$$
\dot{m}_{\text{inj}} = C_{d, \text{inj}} \cdot A_{\text{inj}} \cdot \sqrt{
\frac{2 \gamma}{\gamma -1} \cdot \rho_v \cdot P_1 \cdot
\left[
\left( \frac{P_2}{P_1} \right)^{\frac{2}{\gamma}} -
\left( \frac{P_2}{P_1} \right)^{\frac{\gamma + 1}{\gamma}}
\right]
}
$$

```MATLAB
% Handle potential division by zero or NaN if P1 is zero or negative
if P1 <= 0
    pressure_ratio = Inf; % Ensure non-choked
else
    pressure_ratio = P2 / P1;
end

% Handle potential NaN gamma if cpv or cvv is NaN/zero
if isnan(gamma) || gamma <= 1
    warning('Inj_ICF_VapFeed:InvalidGamma', 'Invalid gamma (%.2f) calculated. Setting mdot_inj = 0.', gamma);
    mdot_inj = 0;
    critical_pressure_ratio = NaN;
else
    % 임계 압력비 계산 (choked flow 조건)
    critical_pressure_ratio = (2 / (gamma + 1))^(gamma / (gamma - 1));

    % 유량 계산
    if pressure_ratio <= critical_pressure_ratio
        % 초크 유동 (Choked flow)
        choked_term = (2 / (gamma + 1))^((gamma + 1) / (gamma - 1));
        % Ensure term inside sqrt is non-negative
        sqrt_term = gamma * P1 * rho_v * choked_term;
        if sqrt_term >= 0
            mdot_inj = Cd_inj * A_inj * sqrt(sqrt_term);
        else
            warning('Inj_ICF_VapFeed:ChokedSqrtNeg', 'Negative value encountered in choked flow sqrt. Setting mdot_inj = 0.');
            mdot_inj = 0;
        end
    else
        % 비초크 유동 (Non-choked flow)
        term1 = (pressure_ratio)^(2 / gamma);
        term2 = (pressure_ratio)^((gamma + 1) / gamma);
        % Ensure term inside sqrt is non-negative
        sqrt_term = (2 * gamma / (gamma - 1)) * rho_v * P1 * (term1 - term2);
         if sqrt_term >= 0
            mdot_inj = Cd_inj * A_inj * sqrt(sqrt_term);
        else
             warning('Inj_ICF_VapFeed:NonChokedSqrtNeg', 'Negative value encountered in non-choked flow sqrt. Setting mdot_inj = 0.');
            mdot_inj = 0;
        end
    end
end
```

# Output

| 명칭        | 기호                                                                 | 출력 변수           | 비고  |
| ----------- | ------------------------------------------------------------------ | --------------- | --- |
| 인젝터 임계 압력비 | $\left( \frac{2}{\gamma + 1} \right)^{\frac{\gamma}{\gamma - 1}}$ | x.inj.ratio_Pcr |     |
| 인젝터 압력 비율   | $\frac{P_2}{P_1}$                                               | x.inj.ratio_P   |     |
| 인젝터 질량 유량   | $\dot{m}_{\text{inj}}$                                            | x.inj.mdot      |     |

```MATLAB
x.inj.ratio_Pcr = critical_pressure_ratio;
x.inj.ratio_P = pressure_ratio;
x.inj.mdot = mdot_inj;
```

# 전체 코드
```MATLAB
function [x] = Inj_ICF_VapFeed(x)
%% Input
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_ICF_VapFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_ICF_VapFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho_v = x.tank.rho_v;
cpv = x.tank.cp_v;
cvv = x.tank.cv_v;
A_inj = x.inj.A;
Cd_inj = x.inj.Cd;

gamma = cpv / cvv; % 비열비 계산

%% System
% Handle potential division by zero or NaN if P1 is zero or negative
if P1 <= 0
    pressure_ratio = Inf; % Ensure non-choked
else
    pressure_ratio = P2 / P1;
end

% Handle potential NaN gamma if cpv or cvv is NaN/zero
if isnan(gamma) || gamma <= 1
    warning('Inj_ICF_VapFeed:InvalidGamma', 'Invalid gamma (%.2f) calculated. Setting mdot_inj = 0.', gamma);
    mdot_inj = 0;
    critical_pressure_ratio = NaN;
else
    % 임계 압력비 계산 (choked flow 조건)
    critical_pressure_ratio = (2 / (gamma + 1))^(gamma / (gamma - 1));

    % 유량 계산
    if pressure_ratio <= critical_pressure_ratio
        % 초크 유동 (Choked flow)
        choked_term = (2 / (gamma + 1))^((gamma + 1) / (gamma - 1));
        % Ensure term inside sqrt is non-negative
        sqrt_term = gamma * P1 * rho_v * choked_term;
        if sqrt_term >= 0
            mdot_inj = Cd_inj * A_inj * sqrt(sqrt_term);
        else
            warning('Inj_ICF_VapFeed:ChokedSqrtNeg', 'Negative value encountered in choked flow sqrt. Setting mdot_inj = 0.');
            mdot_inj = 0;
        end
    else
        % 비초크 유동 (Non-choked flow)
        term1 = (pressure_ratio)^(2 / gamma);
        term2 = (pressure_ratio)^((gamma + 1) / gamma);
        % Ensure term inside sqrt is non-negative
        sqrt_term = (2 * gamma / (gamma - 1)) * rho_v * P1 * (term1 - term2);
         if sqrt_term >= 0
            mdot_inj = Cd_inj * A_inj * sqrt(sqrt_term);
        else
             warning('Inj_ICF_VapFeed:NonChokedSqrtNeg', 'Negative value encountered in non-choked flow sqrt. Setting mdot_inj = 0.');
            mdot_inj = 0;
        end
    end
end

%% Output
x.inj.ratio_Pcr = critical_pressure_ratio;
x.inj.ratio_P = pressure_ratio;
x.inj.mdot = mdot_inj;

end
```
