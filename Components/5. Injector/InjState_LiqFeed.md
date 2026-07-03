---
tags:
  - 2상유동
  - 인젝터
Author: SRS 33기 박호진
---
# 소개
- `InjState_LiqFeed.m`은 **탱크에서 액체 상의 유출이 일어날 때, 인젝터 출구 상태**의 계산을 수행하는 함수이다.
- **등엔트로피 조건**으로 계산을 수행한다.
- 인젝터 입구가 탱크 출구에 바로 연결되어있다는 조건을 적용하였다. (배관 라인 무시)

# Input

| 명칭          | 기호             | 입력 변수      | 비고                        |
| ----------- | -------------- | ---------- | ------------------------- |
| 탱크 내부 유체    | $\text{fluid}$ | x.fluid    | 탱크 내부가 무슨 유체인지 알려줌.       |
| 인젝터 후단 압력  | $P_{\text{downstream}}$ | x.comb.Pinj | 인젝터 하류 압력 (기본). 유효하지 않으면 x.comb.P 사용 |
| 연소실 압력      | $P_{c}$        | x.comb.P   | 인젝터 하류 압력 (대체)        |
| 인젝터 상류 엔트로피 | $s_1$          | x.tank.s_l | 탱크 내부 액체 상의 엔트로피를 취함.     |
| 탱크 내부 온도    | $T_{\text{tank}}$ | x.tank.T   | 솔버 초기 추정값으로 사용        |
| 탱크 내부 액체 밀도 | $\rho_{\text{tank,l}}$ | x.tank.rho_l | 솔버 초기 추정값으로 사용        |

```MATLAB
fluid = x.fluid;
% Pc = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P_downstream = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P_downstream is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P_downstream) || P_downstream <= 0
    warning('InjState_LiqFeed:InvalidPinj', 'Pinj (%.2f Pa) is invalid. Falling back to Pc (%.2f Pa).', P_downstream, x.comb.P);
    P_downstream = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P_downstream) || P_downstream <= 0
        error('InjState_LiqFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) is also invalid. Cannot proceed.', P_downstream);
    end
end

s1 = x.tank.s_l;
geussT = x.tank.T;
geussRho = x.tank.rho_l;
```

# System
- 인젝터 하류(출구)의 상태량 $T_2$와 $\rho_2$를 , 등엔트로피 조건을 적용하여 구한다. 
$$
\begin{align*}
\mathbf{f}(T, \rho) =
\begin{bmatrix}
P(T, \rho) - P_c \\
s_\ell(T, \rho) - s_1
\end{bmatrix}
\end{align*}
$$
$$
\begin{align*}
(T_{2}, \rho_{2}) = \arg \min_{T \geq 0,\ \rho \geq 0} \left\| \mathbf{f}(T, \rho) \right\|^2
\end{align*}
$$
```MATLAB
pFunc = @(v) [ getfield(fluid.GetProps(v(1), v(2)), 'P') - P_downstream;
getfield(fluid.GetProps(v(1), v(2)), 's_l') - s1 ];
v = lsqnonlin(pFunc, [geussT, geussRho], [0, 0], [Inf, Inf], optimset('Display', 'off', 'TolFun', 1e-14));
T2 = v(1); 
rho2 = v(2); 
```

- 3.2 State postulate에 따라 상태 방정식을 이용해 인젝터 하류 전체 상태량 갱신
$$
\mathbf{X} = \left[ P,\ T,\ \chi,\ \rho,\ h,\ s,\ ... \right]^T
$$
$$
\mathbf{X}_{inj}=\textbf{GetProps}(T_{2}, \rho_{2})
$$
```MATLAB
Props = fluid.GetProps(T2, rho2);
```

# Output

| 명칭           | 기호                           | 출력 변수       | 비고                                      |
| ------------ | ---------------------------- | ------------ | --------------------------------------- |
| 인젝터 출구 유체의 상태 | $\text{State}_{\text{inj}}$ | x.inj.state | -1: 오류<br>0: 액체<br>1: 포화<br>2: 기체       |
| 인젝터 출구 압력     | $P_{\text{inj}}$            | x.inj.P     | [Pa]                                    |
| 인젝터 출구 온도     | $T_{\text{inj}}$            | x.inj.T     | [K]                                     |
| 인젝터 출구 건도     | $\chi_{\text{inj}}$         | x.inj.X     | 0~1, 포화 시에만 유효                          |
| 인젝터 출구 밀도     | $\rho_{\text{inj}}$         | x.inj.rho   | [kg/m³]                                 |
| 인젝터 출구 내부에너지 | $u_{\text{inj}}$            | x.inj.u     | [J/kg]                                  |
| 인젝터 출구 엔트로피  | $s_{\text{inj}}$            | x.inj.s     | [J/kg·K]                                |
| 인젝터 출구 엔탈피   | $h_{\text{inj}}$            | x.inj.h     | [J/kg]                                  |
| 인젝터 출구 정압비열  | $c_{p,\text{inj}}$          | x.inj.cp    | [J/kg·K]                                |
| 인젝터 출구 정적비열  | $c_{v,\text{inj}}$          | x.inj.cv    | [J/kg·K]                                |
| 인젝터 출구 증기상 밀도 | $\rho_v$                     | x.inj.rho_v | 증기상                                     |
| 인젝터 출구 증기상 내부에너지 | $u_v$                        | x.inj.u_v   |                                         |
| 인젝터 출구 증기상 엔트로피 | $s_v$                        | x.inj.s_v   |                                         |
| 인젝터 출구 증기상 엔탈피 | $h_v$                        | x.inj.h_v   |                                         |
| 인젝터 출구 증기상 정압비열 | $c_{p,v}$                    | x.inj.cp_v  |                                         |
| 인젝터 출구 증기상 정적비열 | $c_{v,v}$                    | x.inj.cv_v  |                                         |
| 인젝터 출구 액체상 밀도 | $\rho_\ell$                  | x.inj.rho_l | 액상                                      |
| 인젝터 출구 액체상 내부에너지 | $u_\ell$                     | x.inj.u_l   |                                         |
| 인젝터 출구 액체상 엔트로피 | $s_\ell$                     | x.inj.s_l   |                                         |
| 인젝터 출구 액체상 엔탈피 | $h_\ell$                     | x.inj.h_l   |                                         |
| 인젝터 출구 액체상 정압비열 | $c_{p,\ell}$                 | x.inj.cp_l  |                                         |
| 인젝터 출구 액체상 정적비열 | $c_{v,\ell}$                 | x.inj.cv_l  |                                         |

```MATLAB
% 상태 변수
x.inj.state = state; % -1: 오류, 0: 액체, 1: 포화, 2: 기체
x.inj.P = Props.P; % Pa
x.inj.T = Props.T; % K
x.inj.X = Props.X; % 건도

% 혼합물 물성
x.inj.rho = Props.rho; %kg/m^3
x.inj.u = Props.u; % J/kg
x.inj.s = Props.s; % J/kg-K
x.inj.h = Props.h; % J/kg
x.inj.cp = Props.cp; % J/kg-K
x.inj.cv = Props.cv; % J/kg-K

% 증기상 물성
x.inj.rho_v = Props.rho_v; % kg/m^3
x.inj.u_v = Props.u_v; % J/kg
x.inj.s_v = Props.s_v; % J/kg-K
x.inj.h_v = Props.h_v; % J/kg
x.inj.cp_v = Props.cp_v; % J/kg-K
x.inj.cv_v = Props.cv_v; % J/kg-K

% 액상 물성
x.inj.rho_l = Props.rho_l; % kg/m^3
x.inj.u_l = Props.u_l; % J/kg
x.inj.s_l = Props.s_l; % J/kg-K
x.inj.h_l = Props.h_l; % J/kg
x.inj.cp_l = Props.cp_l; % J/kg-K
x.inj.cv_l = Props.cv_l; % J/kg-K

```

# 전체 코드
```MATLAB
function [x] = InjState_LiqFeed(x)
%% Input
fluid = x.fluid;
% Pc = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P_downstream = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P_downstream is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P_downstream) || P_downstream <= 0
    warning('InjState_LiqFeed:InvalidPinj', 'Pinj (%.2f Pa) is invalid. Falling back to Pc (%.2f Pa).', P_downstream, x.comb.P);
    P_downstream = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P_downstream) || P_downstream <= 0
        error('InjState_LiqFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) is also invalid. Cannot proceed.', P_downstream);
    end
end

s1 = x.tank.s_l;
geussT = x.tank.T;
geussRho = x.tank.rho_l;

%% System
% 엔트로피 오차에 가중치 부여 -> 제거
pFunc = @(v) [ (getfield(fluid.GetProps(v(1), v(2)), 'P') - P_downstream);
			   (getfield(fluid.GetProps(v(1), v(2)), 's') - s1) ];

% 솔버 초기 추정값으로 탱크의 온도와 액상 밀도를 사용 (InjState_VapFeed.m 형식 참고)
lb = [183, 2.7];
ub = [309, 1236];
v = lsqnonlin(pFunc, [geussT, geussRho], lb, ub, optimset('Display', 'off', 'TolFun', 1e-10));
T2 = v(1); 
rho2 = v(2); 

Props = fluid.GetProps(T2, rho2, 1);

%% Output
% 상태 변수
x.inj.state = Props.state; % -1: 오류, 0: 액체, 1: 포화, 2: 기체
x.inj.P = Props.P; % Pa
x.inj.T = Props.T; % K
x.inj.X = Props.X; % 건도

% 혼합물 물성
x.inj.rho = Props.rho; %kg/m^3
x.inj.u = Props.u; % J/kg
x.inj.s = Props.s; % J/kg-K
x.inj.h = Props.h; % J/kg
x.inj.cp = Props.cp; % J/kg-K
x.inj.cv = Props.cv; % J/kg-K

% 증기상 물성
x.inj.rho_v = Props.rho_v; % kg/m^3
x.inj.u_v = Props.u_v; % J/kg
x.inj.s_v = Props.s_v; % J/kg-K
x.inj.h_v = Props.h_v; % J/kg
x.inj.cp_v = Props.cp_v; % J/kg-K
x.inj.cv_v = Props.cv_v; % J/kg-K

% 액상 물성
x.inj.rho_l = Props.rho_l; % kg/m^3
x.inj.u_l = Props.u_l; % J/kg
x.inj.s_l = Props.s_l; % J/kg-K
x.inj.h_l = Props.h_l; % J/kg
x.inj.cp_l = Props.cp_l; % J/kg-K
x.inj.cv_l = Props.cv_l; % J/kg-K

end