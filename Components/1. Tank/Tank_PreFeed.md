---
tags:
  - Tank
  - 2상유동
Author: SRS 33기 박호진
---
# 소개
- `Tank_PreFeed.m` 은 **런밸브 작동 전 벤트 포트로만 탱크 내 유체의 유출**이 일어나는 과정의 시스템을 모사한 함수이다.
	- 탱크 내부 벤트 포트의 높이를 넘어선 액체는 존재하지 않았을 때의 상황에서만 이용 가능하다.
- 탱크 내부 상태량 갱신은 ==엔탈피 알고리즘==을 이용한다.
- 탱크 벽에서의 열전달은 고려되지 않았다.
- 벤트 포트로 빠져나간 질량 유량이 존재해야 이 함수를 이용할 수 있다.
- 벤트 포트에서 빠져나간 유체의 상태는 증기(기체)로 가정한다. 
	- 탱크 내부에 아산화질소를 충전할 때, 액체의 아산화질소가 탱크 내부 벤트 포트의 높이 만큼 채워지면 액체는 벤트포트로 빠져나간다. 즉, 벤트 포트 입구는 증기상의 아산화질소와 맞닿아 있게 된다.

# Input

| 명칭             | 기호                      | 입력 변수       | 비고                               |
| -------------- | ----------------------- | ----------- | -------------------------------- |
| 탱크 내부 유체       | $\text{fluid}$          | x.fluid     | 탱크 내부가 무슨 유체인지 알려줌.              |
| 시간 간격          | $\Delta t$              | x.time.dt   |                                  |
| 탱크 유체 질량       | $m_{\text{tank}}$       | x.tank.m    | 탱크 내부 유체 질량임. <br>탱크 벽 질량 포함 안됨. |
| 벤트 포트 유출 질량 유량 | $\dot{m}_{\text{vent}}$ | x.vent.mdot |                                  |
| 탱크 유체 부피       | $V_{\text{tank}}$       | x.tank.V    | 탱크 내부 유체 부피<br>즉, 탱크 내부 부피       |
| 탱크 유체 증기상 비엔탈피 | $h_v$                   | x.tank.hv   |                                  |
| 탱크 유체 총 엔탈피    | $H_{\text{tank}}$       | x.tank.H    |                                  |

```MATLAB
fluid = x.fluid;
dt = x.time.dt;
m_tank = x.tank.m;
mdot_vent = x.vent.mdot;
V_tank = x.tank.V;
hv = x.tank.h_v;
H_tank = x.tank.H;
```



# System
## 1. 탱크 유체 질량 및 밀도 갱신
- 1.1 벤트 포트에서 빠져나간 질량 유량 만큼 질량을 갱신함.
$$
m_{\text{tank}}(t+\Delta t)=m_{\text{tank}}(t) - \dot{m}_{\text{vent}}(t) \Delta t
$$
```MATLAB
m_tank = m_tank - mdot_vent * dt;
```

- 1.2 유체 평균 밀도를 갱신함.
$$
\rho_{\text{tank}}(t+\Delta t) = \frac{m_{\text{tank}}(t+\Delta t)}{V_{\text{tank}}}
$$
```MATLAB
rho_tank = m_tank / V_tank;
```

## 2. 탱크 유체 엔탈피 갱신
- 2.1 벤트 포트에서 빠져나간  **증기 상**의 질량 유량만큼 엔탈피 유량을 계산함.
$$
\dot{H}_{\text{vent}}(t) = \dot{m}_{\text{vent}}(t)h_v(t)
$$
```MATLAB
Hdot_vent = mdot_vent * hv;
```

- 2.2 탱크 평균 엔탈피를 갱신함.
$$
H_{\text{tank}}(t+\Delta t) = H_{\text{tank}}(t) - \dot{H}_{\text{vent}}(t)\Delta t
$$
```MATLAB
H_tank = H_tank - Hdot_vent * dt;
```

- 2.3 탱크 평균 비엔탈피를 갱신함.
$$
h_{\text{tank}}(t+\Delta t) = \frac{H_{\text{tank}}(t+\Delta t)}{m_{\text{tank}}(t+\Delta t)} 
$$
```MATLAB
h_tank = H_tank / m_tank;
```

## 3. 엔탈피 알고리즘
- 3.1 목적 함수 정의 및 비선형 최소제곱 해법을 통해  탱크 온도 갱신

$$
\begin{align*}
f(T) = h(T, \rho_{\text{tank}}(t+\Delta t)) - h_{\text{tank}}(t+\Delta t)
\end{align*}
$$
$$
\begin{align*}
T_{\text{tank}}(t+\Delta t) = \arg \min_{T \geq 0} \left( f(T) \right)^2
\end{align*}
$$
```MATLAB
% Determine initial guess for T_tank
if isfield(x.tank, 'T') && ~isempty(x.tank.T) && isfinite(x.tank.T)
    T_guess = x.tank.T; % Use previous step's temperature as initial guess
else
    T_guess = 300; % Fallback to 300 K if previous T is not available/valid
end

pFunc = @(T_unknown) getfield(fluid.GetProps(T_unknown, rho_tank), 'h') - h_tank;
% Use T_guess as the initial guess in lsqnonlin
T_tank = lsqnonlin(pFunc, T_guess, 0, Inf, optimset('Display', 'off', 'TolFun', 1e-10));
Props = fluid.GetProps(T_tank, rho_tank);
```

- 3.2 State postulate에 따라 상태 방정식을 이용해 탱크 전체 상태량 갱신
$$
\mathbf{X} = \left[ P,\ T,\ \chi,\ \rho,\ h,\ s,\ ... \right]^T
$$
$$
\mathbf{X}_{\text{tank}}(t+\Delta t)=\textbf{GetProps}(T_{\text{tank}}(t+\Delta t), \rho_{\text{tank}}(t+\Delta t))
$$
```MATLAB
Props = fluid.GetProps(T_tank, rho_tank);
```

# Output

| 명칭         | 기호         | 출력 변수        | 단위    | 비고                               |
| ------------ | ---------- | ------------ | ----- | -------------------------------- |
| 상태 변수      | state, P, T, X | x.tank.state, P, T, X | -, Pa, K, - | 업데이트된 탱크 상태 (압력, 온도, 건도 등)   |
| 총 질량       | $m$        | x.tank.m     | kg    | 업데이트된 탱크 내부 총 질량                |
| 증기 질량     | $m_v$      | x.tank.m_v   | kg    | 업데이트된 증기 질량 ($m \times X$)       |
| 액체 질량     | $m_l$      | x.tank.m_l   | kg    | 업데이트된 액체 질량 ($m \times (1-X)$)   |
| 혼합물 물성    | $\rho, u, s, ...$ | x.tank.rho, u, s, ... | SI 단위 | 업데이트된 혼합물 물성치                 |
| 증기상 물성    | $\rho_v, u_v, ...$ | x.tank.rho_v, u_v, ... | SI 단위 | 업데이트된 증기상 물성치                 |
| 액상 물성     | $\rho_l, u_l, ...$ | x.tank.rho_l, u_l, ... | SI 단위 | 업데이트된 액상 물성치                 |
| 총 엔트로피    | $S$        | x.tank.S     | J/K   | 업데이트된 총 엔트로피 ($m \times s$)      |
| 총 엔탈피     | $H$        | x.tank.H     | J     | 업데이트된 총 엔탈피 ($m \times h$)      |


```MATLAB
% 상태 변수
x.tank.state = state; % -1: 오류, 0: 액체, 1: 포화, 2: 기체
x.tank.P = Props.P; % Pa
x.tank.T = Props.T; % K
x.tank.X = Props.X; % 건도

% 혼합물 물성
x.tank.rho = Props.rho; %kg/m^3
x.tank.u = Props.u; % J/kg
x.tank.s = Props.s; % J/kg-K
x.tank.h = Props.h; % J/kg
x.tank.cp = Props.cp; % J/kg-K
x.tank.cv = Props.cv; % J/kg-K
x.tank.S = m_tank * Props.s; % J/K
x.tank.H = m_tank * Props.h; % J

% 증기상 물성
x.tank.rho_v = Props.rho_v; % kg/m^3
x.tank.u_v = Props.u_v; % J/kg
x.tank.s_v = Props.s_v; % J/kg-K
x.tank.h_v = Props.h_v; % J/kg
x.tank.cp_v = Props.cp_v; % J/kg-K
x.tank.cv_v = Props.cv_v; % J/kg-K

% 액상 물성
x.tank.rho_l = Props.rho_l; % kg/m^3
x.tank.u_l = Props.u_l; % J/kg
x.tank.s_l = Props.s_l; % J/kg-K
x.tank.h_l = Props.h_l; % J/kg
x.tank.cp_l = Props.cp_l; % J/kg-K
x.tank.cv_l = Props.cv_l; % J/kg-K

```

# 전체 코드
```MATLAB
function [x] = Tank_PreFeed(x)
%% Input
fluid = x.fluid;
dt = x.time.dt;
m_tank = x.tank.m;
mdot_vent = x.vent.mdot;
V_tank = x.tank.V;
hv = x.tank.h_v;
H_tank = x.tank.H;

%% System
m_tank = m_tank - mdot_vent * dt;
rho_tank = m_tank / V_tank;

Hdot_vent = mdot_vent * hv;
H_tank = H_tank - Hdot_vent * dt;
h_tank = H_tank / m_tank;

% Determine initial guess for T_tank
if isfield(x.tank, 'T') && ~isempty(x.tank.T) && isfinite(x.tank.T)
    T_guess = x.tank.T; % Use previous step's temperature as initial guess
else
    T_guess = 300; % Fallback to 300 K if previous T is not available/valid
end

pFunc = @(T_unknown) getfield(fluid.GetProps(T_unknown, rho_tank), 'h') - h_tank;
% Use T_guess as the initial guess in lsqnonlin
T_tank = lsqnonlin(pFunc, T_guess, 0, Inf, optimset('Display', 'off', 'TolFun', 1e-10));
Props = fluid.GetProps(T_tank, rho_tank);

%% Output
% 상태 변수
x.tank.state = Props.state; % -1: 오류, 0: 액체, 1: 포화, 2: 기체
x.tank.P = Props.P; % Pa
x.tank.T = Props.T; % K
x.tank.X = Props.X; % 건도
x.tank.m = m_tank; % Store updated total mass
% 액체 및 증기 질량 업데이트
x.tank.m_v = x.tank.m * x.tank.X;     % 증기 질량
x.tank.m_l = x.tank.m * (1 - x.tank.X); % 액체 질량

% 혼합물 물성
x.tank.rho = Props.rho; %kg/m^3
x.tank.u = Props.u; % J/kg
x.tank.s = Props.s; % J/kg-K
x.tank.h = Props.h; % J/kg
x.tank.cp = Props.cp; % J/kg-K
x.tank.cv = Props.cv; % J/kg-K
x.tank.S = m_tank * Props.s; % J/K
x.tank.H = m_tank * Props.h; % J

% 증기상 물성
x.tank.rho_v = Props.rho_v; % kg/m^3
x.tank.u_v = Props.u_v; % J/kg
x.tank.s_v = Props.s_v; % J/kg-K
x.tank.h_v = Props.h_v; % J/kg
x.tank.cp_v = Props.cp_v; % J/kg-K
x.tank.cv_v = Props.cv_v; % J/kg-K

% 액상 물성
x.tank.rho_l = Props.rho_l; % kg/m^3
x.tank.u_l = Props.u_l; % J/kg
x.tank.s_l = Props.s_l; % J/kg-K
x.tank.h_l = Props.h_l; % J/kg
x.tank.cp_l = Props.cp_l; % J/kg-K
x.tank.cv_l = Props.cv_l; % J/kg-K

end
```