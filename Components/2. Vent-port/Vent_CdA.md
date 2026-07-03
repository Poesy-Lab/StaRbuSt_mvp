---
tags:
  - Vent
  - CdA
Author: 박호진 (Generated based on Vent_ICF.md and Inj_CdA_LiqFeed.md)
---
# 소개
- `Vent_CdA.m`은 **벤트 포트로부터 탱크 상단의 증기 상의 유체 유출**이 일어나는 과정의 시스템을 모사한 함수입니다.
- 벤트 포트의 열전달은 고려되지 않았습니다.
- 벤트 포트 질량 유량 공식은 **CdA 모델**을 이용합니다.
    - 이 모델은 비압축성 또는 저속 유동, 특히 압력 차이가 크지 않아 초크(choked)되지 않는 경우에 적합할 수 있습니다.
    - 초크 유동 가능성이 높은 경우에는 `Vent_ICF.m`의 ICF 모델이 더 적합할 수 있습니다.

# Input

| 명칭              | 기호                   | 입력 변수        | 비고         |
| --------------- | -------------------- | ------------ | ---------- |
| 탱크 내부 압력        | $P_{\text{tank}}$    | x.tank.P     | 벤트 포트 상류 압력 |
| 탱크 외부 압력        | $P_{\text{ambient}}$ | x.amb.P      | 벤트 포트 하류 압력 |
| 탱크 내부 증기상 유체 밀도 | $\rho_v$             | x.tank.rho_v | 벤트 포트 상류 밀도 |
| 벤트 포트 출구 면적     | $A_{\text{vent}}$    | x.vent.A     |            |
| 벤트 포트 유량 계수     | $C_{d, \text{vent}}$ | x.vent.Cd    |            |

```MATLAB
P_tank = x.tank.P;
P_amb = x.amb.P;
rhov = x.tank.rho_v;
A_vent = x.vent.A;
Cd_vent = x.vent.Cd;
```

# System
- 일반적인 CdA 모델의 공식은 다음과 같습니다.
$$
\dot{m}_{\text{vent}} = C_{d,\text{vent}} \cdot A_{\text{vent}} \cdot \sqrt{2 \rho_v \left( P_{\text{tank}} - P_{\text{ambient}} \right)}
$$
- 압력 강하 ($\Delta P = P_{\text{tank}} - P_{\text{ambient}}$)가 0보다 작거나 같으면 유량은 0으로 계산됩니다.

```MATLAB
deltaP = P_tank - P_amb;

if deltaP <= 0
    mdot_vent = 0;
else
    mdot_vent = Cd_vent * A_vent * sqrt(2 * rhov * deltaP);
end
```

# Output

| 명칭           | 기호                   | 출력 변수     | 비고   |
| ------------ | -------------------- | --------- | ---- |
| 벤트 포트 질량 유량 | $\dot{m}_{\text{vent}}$ | x.vent.mdot | [kg/s] |

```MATLAB
x.vent.mdot = mdot_vent;
```

# 전체 코드
```MATLAB
function [x] = Vent_CdA(x)
%% Input
P_tank = x.tank.P;
P_amb = x.amb.P;
rhov = x.tank.rho_v;
A_vent = x.vent.A;
Cd_vent = x.vent.Cd;

%% System
deltaP = P_tank - P_amb;

if deltaP <= 0
    mdot_vent = 0;
else
    mdot_vent = Cd_vent * A_vent * sqrt(2 * rhov * deltaP);
end

%% Output
x.vent.mdot = mdot_vent;

end
``` 