---
tags:
  - Vent
  - 2상유동
Author: 박호진
---
# 소개
- `Vent.m`은 **벤트 포트로부터 탱크 상단의 증기 상의 유체 유출**이 일어나는 과정의 시스템을 모사한 함수이다.
- 벤트 포트의 열전달은 고려되지 않았다.
- 벤트 포트 질량 유량 공식은 ICF(Isentropic Choked Flow)모델을 이용한다.

# Input

| 명칭              | 기호                   | 입력 변수        | 비고  |
| --------------- | -------------------- | ------------ | --- |
| 탱크 내부 압력        | $P_{\text{tank}}$    | x.tank.P     |     |
| 탱크 외부 압력        | $P_{\text{ambient}}$ | x.amb.P      |     |
| 탱크 내부 증기상 유체 밀도 | $\rho_v$             | x.tank.rho_v |     |
| 탱크 내부 증기상 정압 비열 | $c_{p,v}$            | x.tank.cp_v  |     |
| 탱크 내부 증기상 정적 비열 | $c_{v,v}$            | x.tank.cv_v  |     |
| 벤트 포트 출구 면적     | $A_{\text{vent}}$    | x.vent.A     |     |
| 벤트 포트 유량 계수     | $C_{d, \text{vent}}$ | x.vent.Cd    |     |

```MATLAB
P_tank = x.tank.P;
P_amb = x.amb.P;
rhov = x.tank.rho_v;
cpv = x.tank.cp_v;
cvv = x.tank.cv_v;
A_vent = x.vent.A;
Cd_vent = x.vent.Cd;

gamma = cpv / cvv;
```

# System
- 벤트 포트로 유출되는 흐름이 초크 유동인지 판별해야 함. 아래 조건을 만족하면 초크 유동임.
$$
\frac{P_{\text{ambient}}}{P_{\text{tank}}} \le \left( \frac{2}{\gamma + 1} \right)^{\frac{\gamma}{\gamma - 1}}
$$

- 초크 유동일 시, 벤트 포트로 유출된 질량 유량은 다음과 같음.
$$
\dot{m}_{\text{vent}} =  C_{d,\text{vent}} \cdot A_{\text{vent}} \cdot \sqrt{ \gamma \cdot \rho_v \cdot P_{\text{tank}} \cdot \left( \frac{2}{\gamma + 1} \right)^{\frac{\gamma + 1}{\gamma - 1}} }
$$

- 비초크 유동일 시, 벤트 포트로 유출된 질량 유량은 다음과 같음.
$$
\dot{m}_{\text{vent}} = C_{d, \text{vent}} \cdot A_{\text{vent}} \cdot \sqrt{
\frac{2 \gamma}{\gamma -1} \cdot \rho_v \cdot P_{\text{tank}} \cdot
\left[
\left( \frac{P_{\text{ambient}}}{P_{\text{tank}}} \right)^{\frac{2}{\gamma}} -
\left( \frac{P_{\text{ambient}}}{P_{\text{tank}}} \right)^{\frac{\gamma + 1}{\gamma}}
\right]
}
$$

```MATLAB
% 임계 압력비 계산 (choked flow 조건)
critical_pressure_ratio = (2 / (gamma + 1))^(gamma / (gamma - 1));
pressure_ratio = P_amb / P_tank;

% 유량 계산
if pressure_ratio <= critical_pressure_ratio
    % 초크 유동
    mdot_vent = Cd_vent * A_vent * sqrt( ...
        gamma * P_tank * rhov * ...
        (2 / (gamma + 1))^((gamma + 1) / (gamma - 1)) );
else
    % 비초크 유동
    term1 = (P_amb / P_tank)^(2 / gamma);
    term2 = (P_amb / P_tank)^((gamma + 1) / gamma);
    mdot_vent = Cd_vent * A_vent * sqrt( ...
        (2 * gamma / (gamma - 1)) * rhov * P_tank * (term1 - term2) );
end
```

# Output

| 명칭           | 기호                                                                | 출력 변수            | 비고  |
| ------------ | ----------------------------------------------------------------- | ---------------- | --- |
| 벤트 포트 임계 압력비 | $\left( \frac{2}{\gamma + 1} \right)^{\frac{\gamma}{\gamma - 1}}$ | x.vent.ratio_Pcr |     |
| 벤트 포트 압력 비율  | $\frac{P_{\text{ambient}}}{P_{\text{tank}}}$                      | x.vent.ratio_P   |     |
| 벤트 포트 질량 유량  | $\dot{m}_{\text{vent}}$                                           | x.vent.mdot      |     |

```MATLAB
x.vent.ratio_Pcr = critical_pressure_ratio;
x.vent.ratio_P = pressure_ratio;
x.vent.mdot = mdot_vent;
```

# 전체 코드
```MATLAB
function [x] = Vent_ICF(x)
%% Input
P_tank = x.tank.P;
P_amb = x.amb.P;
rhov = x.tank.rho_v;
cpv = x.tank.cp_v;
cvv = x.tank.cv_v;
A_vent = x.vent.A;
Cd_vent = x.vent.Cd;

gamma = cpv / cvv;

%% System
% 임계 압력비 계산 (choked flow 조건)
critical_pressure_ratio = (2 / (gamma + 1))^(gamma / (gamma - 1));
pressure_ratio = P_amb / P_tank;

% 유량 계산
if pressure_ratio <= critical_pressure_ratio
    % 초크 유동
    mdot_vent = Cd_vent * A_vent * sqrt( ...
        gamma * P_tank * rhov * ...
        (2 / (gamma + 1))^((gamma + 1) / (gamma - 1)) );
else
    % 비초크 유동
    term1 = (P_amb / P_tank)^(2 / gamma);
    term2 = (P_amb / P_tank)^((gamma + 1) / gamma);
    mdot_vent = Cd_vent * A_vent * sqrt( ...
        (2 * gamma / (gamma - 1)) * rhov * P_tank * (term1 - term2) );
end

%% Output
x.vent.ratio_Pcr = critical_pressure_ratio;
x.vent.ratio_P = pressure_ratio;
x.vent.mdot = mdot_vent;

end
```