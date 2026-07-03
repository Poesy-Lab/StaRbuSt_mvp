---
tags:
  - 인젝터
  - 2상유동
  - CdA
Author: SRS 33기 박호진
---
# 소개
- `Inj_CdA_LiqFeed.m`은 **탱크 하단 출구에서 액체의 유출이 일어날 때, 인젝터에서 유체의 유출**이 일어나는 과정의 시스템을 모사한 함수이다.
- 일반적인 샤워 헤드형 인젝터로 가정한다.
- 질량 유량 공식은 CdA 모델을 이용한다.
	- 비압축성 또는 저속 유동 조건에서 높은 정확도를 보여준다.
- 인젝터 입구가 탱크 출구에 바로 연결되어있다는 조건을 적용하였다. (배관 라인 무시)

# Input

| 명칭       | 기호                  | 입력 변수        | 비고        |
| -------- | ------------------- | ------------ | --------- |
| 탱크 내부 압력 | $P_1$               | x.tank.P     | 인젝터 상류 압력 |
| 연소실 압력   | $P_2$               | x.comb.P     | 인젝터 하류 압력 |
| 탱크 액체 밀도 | $\rho_1$            | x.tank.rho_l | 인젝터 상류 밀도 |
| 인젝터 면적   | $A_{\text{inj}}$    | x.inj.A      |           |
| 인젝터 유량계수 | $C_{d, \text{inj}}$ | x.inj.Cd     |           |

```MATLAB
P1 = x.tank.P;
P2 = x.comb.P;
rho_1 = x.tank.rho_l;
A_inj = x.inj.A;
Cd_inj = x.inj.Cd;
```

# System
- 일반적인 CdA 모델의 공식은 다음과 같음.
$$
\dot{m}_{\text{inj}} = C_{d,\text{inj}} \cdot A_{\text{inj}} \cdot \sqrt{2 \rho_1 \left( P_1 - P_2 \right)}
$$
- 압력 강하 ($\Delta P = P_1 - P_2$)가 0보다 작거나 같으면 유량은 0으로 계산됩니다.

```MATLAB
deltaP = P1 - P2;

if deltaP <= 0
    mdot_inj = 0;
else
    mdot_inj = Cd_inj * A_inj * sqrt(2 * rho_1 * deltaP);
end
```

# Output

| 명칭      | 기호                      | 출력 변수     | 비고  |
| ------- | ----------------------- | --------- | --- |
| 인젝터 질량 유량 | $\dot{m}_{\text{inj}}$ | x.inj.mdot |     |

```MATLAB
x.inj.mdot = mdot_inj;
```

# 전체 코드
```MATLAB
function [x] = Inj_CdA_LiqFeed(x)
%% Input
P1 = x.tank.P;
P2 = x.comb.P;
rho_1 = x.tank.rho_l;
A_inj = x.inj.A;
Cd_inj = x.inj.Cd;

%% System
deltaP = P1 - P2;

if deltaP <= 0
    mdot_inj = 0;
else
    mdot_inj = Cd_inj * A_inj * sqrt(2 * rho_1 * deltaP);
end

%% Output
x.inj.mdot = mdot_inj;

end