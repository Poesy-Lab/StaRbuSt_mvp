---
tags:
  - 그레인
  - 후퇴율
  - 순간값 계산
Author: SRS 33기 박호진
lastmod: 2024-05-01 # 최종 수정일
---
# 소개
- `Grain_aGn.m`은 **주어진 현재 그레인 내경(`x.fuel.R`)과 산화제 유량(`x.inj.mdot`)을 기반으로 순간적인 연료 그레인의 후퇴율, 연료 질량 유량, 단면적, 연소 면적**을 계산하는 함수입니다.
- 산화제 유속($G_{ox}$)과 후퇴율 계수($a, n$)를 이용하여 후퇴율($\dot{r}$)을 계산합니다.
- **이 함수는 시간 스텝(`dt`)을 사용하지 않으며, 다음 스텝의 그레인 내경을 직접 계산하거나 업데이트하지 않습니다.** 시간 적분 및 내경 업데이트는 이 함수를 호출하는 상위 함수(예: `LiqFeed.m`)에서 수행해야 합니다.
- 입력된 현재 내경(`R_current`)이 이미 외경(`R_out`) 이상이거나 산화제 유량이 0 이하일 경우, 후퇴율과 관련 값들을 0으로 계산합니다.

# Input

| 명칭          | 기호              | 입력 변수       | 비고                   |
| ----------- | --------------- | ----------- | ---------------------- |
| 인젝터 분사 질량유량 | $\dot{m}_{inj}$ | x.inj.mdot  | [kg/s]                 |
| 연료 포트 개수    | $N$             | x.fuel.N    | -                      |
| **현재** 연료 포트 반경 | $R_{\text{current}}$ | **x.fuel.R**  | **[m], 계산의 기준이 되는 현재 내경** |
| **그레인 외경**    | $R_{out}$       | **x.fuel.R_out**| **[m], 번아웃 확인용**     |
| 그레인 길이       | $L$             | x.fuel.L    | [m]                    |
| 연소율 계수      | $a$             | x.fuel.a    | 후퇴율 계수              |
| 연소율 지수      | $n$             | x.fuel.n    | 후퇴율 지수              |
| 연료 밀도       | $\rho_f$        | x.fuel.rho  | [kg/m³]                |

*참고: `dt`는 더 이상 이 함수의 입력이 아닙니다.*

```MATLAB
% Input Extraction 예시 (실제 코드는 아래 전체 코드 참조)
mdot_ox = x.inj.mdot;
N = x.fuel.N;
R_current = x.fuel.R; % 현재 내경 사용
R_out = x.fuel.R_out;
L = x.fuel.L;
a = x.fuel.a;
n = x.fuel.n;
rho_f = x.fuel.rho;
```

# System
## 1. 현재 형상 기반 계산 및 번아웃/무유량 확인
- **1.1 번아웃 또는 무유량 확인**: 입력된 `R_current`가 `R_out`보다 크거나 같거나, `mdot_ox`가 0 이하인지 확인합니다.
    - 해당될 경우: `Gox`, `rdot_mm_s`, `mdot_f`를 0으로 설정합니다. 연소 면적 `Ab`도 0으로 설정합니다. (단, `Ap`는 현재 반지름으로 계산)
    - 해당되지 않을 경우: 아래 계산을 계속 진행합니다.
```MATLAB
if R_current >= R_out
    % ... (Gox, rdot, mdot_f, Ab = 0 설정)
elif mdot_ox <= 0
    % ... (Gox, rdot, mdot_f = 0 설정)
else
    % ... (아래 계산 수행)
end
```
- **1.2 현재 포트 단면적 계산** (단위: m²)
$$ A_p = \pi R_{\text{current}}^2 $$
```MATLAB
Ap = pi * R_current^2;
```
- **1.3 현재 연소 표면적 계산** (단위: m², 번아웃 시 0)
$$ A_b = 2 \pi R_{\text{current}} L $$
```MATLAB
Ab = 2 * pi * R_current * L;
```
- **1.4 산화제 유속 계산** (단위: kg/m²⋅s, 번아웃/무유량 시 0)
$$ G_{\text{ox}} = \frac{\dot{m}_{\text{ox}}}{N \cdot A_p} $$
```MATLAB
Gox = mdot_ox / (N * Ap);
```
- **1.5 후퇴율 계산** (단위: mm/s, 번아웃/무유량 시 0)
$$ \dot{r} = a \cdot G_{\text{ox}}^n $$
```MATLAB
rdot_mm_s = a * Gox^n;
```
- **1.6 연료 질량 유량 계산** (단위: kg/s, 번아웃/무유량 시 0)
$$ \dot{m}_{\text{fuel}} = (\dot{r} \cdot 10^{-3}) \cdot (N \cdot A_b) \cdot \rho_f $$
```MATLAB
mdot_f = ( rdot_mm_s * 1e-3 ) * ( N * Ab ) * rho_f;
```

# Output

| 명칭            | 기호              | 출력 변수        | 비고                                       |
| ------------- | --------------- | ------------ | ------------------------------------------ |
| 산화제 유속       | $G_{ox}$        | x.fuel.Gox   | [kg/m²⋅s], 현재 `R` 기준, 번아웃/무유량 시 0  |
| 후퇴율          | $\dot{r}$       | x.fuel.rdot  | [mm/s], 현재 `R` 기준, 번아웃/무유량 시 0   |
| 연료 질량유량     | $\dot{m}_f$     | x.fuel.mdot  | [kg/s], 현재 `R` 기준, 번아웃/무유량 시 0    |
| 현재 포트 단면적  | $A_p$           | x.fuel.Ap    | [m²], 현재 `R` 기준                          |
| 현재 연소 표면적  | $A_b$           | x.fuel.Ab    | [m²], 현재 `R` 기준, 번아웃 시 0           |

*참고: 출력 구조체 `x`에서 `x.fuel.R` 필드는 입력값 그대로 유지되며, 이 함수에 의해 업데이트되지 않습니다. `x.fuel.dR_m` 필드도 계산되거나 업데이트되지 않습니다.*

```MATLAB
% Output Update (Instantaneous values based on R_current)
x.fuel.Gox = Gox;
x.fuel.rdot = rdot_mm_s; % Output regression rate calculated with R_current
x.fuel.mdot = mdot_f;    % Output fuel mass flow rate calculated with R_current
x.fuel.Ap = Ap;          % Output port area calculated with R_current
x.fuel.Ab = Ab;          % Output burn area calculated with R_current
% x.fuel.R is NOT updated here
% x.fuel.dR_m is NOT calculated or updated here
```

# 전체 코드
```MATLAB
function [x] = Grain_aGn(x)
% Grain_aGn Calculates instantaneous fuel regression rate, mass flow, and areas
%           based on the a*G^n model using the current grain radius.
%
% Inputs:
%   x: Structure containing current system state, must include:
%       x.inj.mdot: Oxidizer mass flow rate (kg/s)
%       x.fuel.N: Number of ports
%       x.fuel.R: Current inner radius (m)
%       x.fuel.L: Grain length (m)
%       x.fuel.a: Regression rate coefficient a
%       x.fuel.n: Regression rate exponent n
%       x.fuel.rho: Fuel density (kg/m^3)
%       x.fuel.R_out: Outer radius (m) - Needed for burnout check
%
% Outputs:
%   x: Updated structure with instantaneous values based on input x.fuel.R:
%       x.fuel.Gox: Oxidizer mass flux (kg/m^2-s)
%       x.fuel.rdot: Regression rate (mm/s)
%       x.fuel.mdot: Fuel mass flow rate (kg/s)
%       x.fuel.Ap: Port area based on current radius (m^2)
%       x.fuel.Ab: Burn area based on current radius (m^2)
% Note: This function DOES NOT update x.fuel.R for the next time step.
%       Time integration must be handled by the calling function.

%% Input Extraction
mdot_ox = x.inj.mdot;
N = x.fuel.N;
R_current = x.fuel.R; % Use current radius for this step's calculations
L = x.fuel.L;
a = x.fuel.a;
n = x.fuel.n;
rho_f = x.fuel.rho;
% dt is no longer needed here
R_out = x.fuel.R_out; % Needed for potential burnout impact on rates

%% Calculations based on Current Radius

% Check for burnout condition based on input radius first
if R_current >= R_out
    % If already burned out at the start of this calculation
    Gox = 0;
    rdot_mm_s = 0;
    mdot_f = 0;
    Ap = pi * R_current^2; % Area still exists
    Ab = 0; % No burn area if already burned out
    % fprintf('Grain already burned out at R=%.4f >= R_out=%.4f\n', R_current, R_out);
elif mdot_ox <= 0 % Also check if there is any oxidizer flow
    Gox = 0;
    rdot_mm_s = 0;
    mdot_f = 0;
    Ap = pi * R_current^2;
    Ab = 2 * pi * R_current * L;
else
    % Normal calculation if not burned out and oxidizer flows
    Ap = pi * R_current^2; % Port area based on current radius
    Ab = 2 * pi * R_current * L; % Burn area based on current radius

    % Oxidizer mass flux
    Gox = mdot_ox / (N * Ap); % kg/m^2*s

    % Regression rate
    rdot_mm_s = a * Gox^n; % mm/s

    % Calculate fuel mass flow rate
    mdot_f = ( rdot_mm_s * 1e-3 ) * ( N * Ab ) * rho_f; % kg/s
end

%% Output Update (Instantaneous values based on R_current)
x.fuel.Gox = Gox;
x.fuel.rdot = rdot_mm_s; % Output regression rate calculated with R_current
x.fuel.mdot = mdot_f;    % Output fuel mass flow rate calculated with R_current
x.fuel.Ap = Ap;          % Output port area calculated with R_current
x.fuel.Ab = Ab;          % Output burn area calculated with R_current
% x.fuel.R is NOT updated here
% x.fuel.dR_m is NOT calculated or updated here

end
```
