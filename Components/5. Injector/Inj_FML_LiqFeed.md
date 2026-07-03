---
tags:
  - 2상유동
  - 인젝터
  - FML
  - ChokedFlow
Author: SRS 33기 박호진
---
# 소개
- `Inj_FML_LiqFeed.m`은 **탱크에서 액체 상의 유출이 일어날 때, 인젝터에서의 2상 질량 유량**을 FML(Foletti–Magni–La Luna) 모델로 계산하는 함수입니다.
- 출처: S. La Luna, N. Foletti, L. Magni, D. Zuin, F. Maggi, *"A Two-Phase Mass Flow Rate Model for Nitrous Oxide Based on Void Fraction"*, Aerospace 2022, 9(12), 828. ([로컬 사본](../../docs/paper/2022_LaLuna/2022_LaLuna.md))
- FML은 Dyer(NHNE) 모델의 직접적인 개선판으로, 일반화 NHNE 계열에 속하며 기존 `Inj_NHNE_LiqFeed.m`과 다음 세 가지가 다릅니다:
	1. **가중치**: 비평형 파라미터 $\kappa$ 대신 **오리피스 하류 보이드율 $\alpha_2$** (등엔트로피 팽창 건도 + Zivi 슬립비 기반)를 사용 → 탱크가 포화 상태일 때 $\kappa=1$로 퇴화하는 Dyer의 한계(단순 산술 평균)를 해소하고, 탱크 내부 정확한 상태(온도)를 몰라도 포화 가정만으로 적용 가능.
	2. **단상 항**: SPI(비압축성) 대신 **SPC(단상 압축성, 실기체 등엔트로피 지수 $n$ 적용)** 사용.
	3. **초킹 판정**: SPC와 HEM 두 기여 항에 **공통 임계 압력비 기준**을 적용하여 초크 유동 예측 가능 (Dyer 모델은 초킹 판정 불가).
- 액상 유출 시 가중식 (논문 식 (22)): 하류에서 플래싱이 강할수록($\alpha_2 \to 1$) HEM 기여가 커지고, 액상이 유지될수록($\alpha_2 \to 0$) SPC 기여가 커집니다.
- **선행 조건**: `InjState_LiqFeed.m`이 먼저 호출되어 하류 등엔트로피 상태(`x.inj.rho`, `x.inj.h`, `x.inj.X`, `x.inj.rho_l`, `x.inj.rho_v`)가 계산되어 있어야 합니다. (`Save_Input_Config.m`의 `u.inj.model_LiqFeed`에 **"FML"** 키워드를 포함해 지정하면 `System/LiqFeed.m`의 모델 분기에서 호출됨)
- 인젝터 입구가 탱크 출구에 바로 연결되어있다는 조건을 적용하였다. (배관 라인 무시)
# Input

| 명칭            | 기호               | 입력 변수         | 비고                                       |
| ------------- | ---------------- | ------------- | ---------------------------------------- |
| 인젝터 상류 압력     | $P_1$            | x.tank.P      | 인젝터 상부 압력                                |
| 인젝터 후단 압력     | $P_2$            | x.comb.Pinj   | 인젝터 하류 압력 (기본). 유효하지 않으면 x.comb.P 사용     |
| 연소실 압력        | $P_c$            | x.comb.P      | 인젝터 하류 압력 (대체)                           |
| 인젝터 상류 액상 밀도  | $\rho_1$         | x.tank.rho_l  | 상류 밀도 (탱크 액체 상의 밀도)                      |
| 인젝터 상류 엔탈피    | $h_1$            | x.tank.h_l    | 상류 액상 엔탈피                                |
| 인젝터 상류 엔트로피   | $s_1$            | x.tank.s_l    | 초크 시 하류 상태 재계산(등엔트로피)에 사용                |
| 탱크 온도         | $T_1$            | x.tank.T      | 상류 음속 조회(EOS 액체 강제 호출) → $n$ 정확 계산에 사용   |
| 상류 액상 정압 비열   | $c_{p,l}$        | x.tank.cp_l   | $n$ 폴백 근사($c_{p,l}/c_{v,l}$)에 사용            |
| 상류 액상 정적 비열   | $c_{v,l}$        | x.tank.cv_l   | $n$ 폴백 근사($c_{p,l}/c_{v,l}$)에 사용            |
| 하류 혼합 밀도      | $\rho_2$         | x.inj.rho     | `InjState_LiqFeed` 계산 결과 (등엔트로피 팽창 상태)   |
| 하류 혼합 엔탈피     | $h_2$            | x.inj.h       | `InjState_LiqFeed` 계산 결과                 |
| 하류 건도         | $x_2$            | x.inj.X       | `InjState_LiqFeed` 계산 결과 (등엔트로피 건도)      |
| 하류 포화 액상 밀도   | $\rho_{2,l}$     | x.inj.rho_l   | 슬립비·보이드율 계산에 사용                          |
| 하류 포화 증기상 밀도  | $\rho_{2,v}$     | x.inj.rho_v   | 슬립비·보이드율 계산에 사용                          |
| 하류 온도         | $T_2$            | x.inj.T       | 초크 시 상태 재계산 솔버의 초기 추정값                   |
| 인젝터 면적        | $A_{\text{inj}}$ | x.inj.A       | 인젝터 유효 단면적                               |
| 인젝터 유량계수      | $C_{d,\text{inj}}$ | x.inj.Cd    | 인젝터 유량 계수                                |

```matlab
fluid = x.fluid;
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_FML_LiqFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_FML_LiqFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho1 = x.tank.rho_l;
h1 = x.tank.h_l;
s1 = x.tank.s_l;
T1 = x.tank.T;     % 상류 음속 조회용 (n 정확 계산)
cp1 = x.tank.cp_l; % n 폴백 근사용
cv1 = x.tank.cv_l; % n 폴백 근사용

% 하류 등엔트로피 상태 (InjState_LiqFeed가 먼저 호출되어 있어야 함)
rho2 = x.inj.rho;
h2 = x.inj.h;
X2 = x.inj.X;         % 하류 건도 (등엔트로피 팽창 기준)
rho2_l = x.inj.rho_l; % 하류 포화 액상 밀도
rho2_v = x.inj.rho_v; % 하류 포화 증기상 밀도
T2_guess = x.inj.T;   % 초크 시 재계산용 초기 추정값
rho2_guess = x.inj.rho;

A_inj = x.inj.A;
Cd_inj = x.inj.Cd;
```

# System
- **실기체 등엔트로피 지수** $n$ (논문 식 (8)):
$$
n = \gamma \left[ \frac{Z + T\left(\frac{\partial Z}{\partial T}\right)_{\rho}}{Z + T\left(\frac{\partial Z}{\partial T}\right)_{P}} \right]
$$
  압축성 인자 $Z$의 도함수가 필요해 보이지만, Helmholtz EOS(`Props/HelmholtzEOS.m`)의 무차원 도함수($\delta = \rho/\rho_c$, $\tau = T_c/T$)로 두 항을 전개하면 닫힌 형태로 정리됩니다:
$$
Z + T\left(\frac{\partial Z}{\partial T}\right)_{\rho} = 1 + \delta\varphi^r_\delta - \delta\tau\varphi^r_{\delta\tau} \equiv A,
\qquad
Z + T\left(\frac{\partial Z}{\partial T}\right)_{P} = \frac{Z \cdot A}{B},
\quad B \equiv 1 + 2\delta\varphi^r_\delta + \delta^2\varphi^r_{\delta\delta}
$$
$$
\therefore \; n = \gamma \, \frac{B}{Z} = \frac{\rho \, c^2}{P}
$$
  (마지막 등호는 `HelmholtzEOS.m`의 $c_p$, $c_v$, $c$(음속) 정의를 대입하면 확인됨.) 즉 식 (8)의 $n$은 실기체 등엔트로피 지수 $\rho c^2 / P$와 **정확히 동치**이므로, $(\partial Z/\partial T)$ 도함수를 EOS에 추가할 필요 없이 EOS가 이미 출력하는 음속 $c$로 정확하게 계산합니다. 상류 액상 상태 $(T_1, \rho_1)$에서 자기일관되게 평가하며(액체 상 강제 조회), 음속 조회에 실패하면 비열비 근사 $n \approx c_{p,l}/c_{v,l}$로 폴백합니다 (이상기체 극한에서 $n \to \gamma$).
$$
n = \frac{\rho_1 \, c_1^2}{P_1^{\text{EOS}}}, \qquad c_1 = c \big|_{(T_1, \rho_1),\, \text{액체 강제}}
$$

- **임계 압력비 및 초킹 판정** (논문 식 (11)): SPC·HEM 두 기여 항에 공통(단일 기준)으로 적용합니다. $n \le 1$이면 식 (7)의 유효 범위를 벗어나므로 SPI로 폴백합니다.
$$
\left( \frac{P_2}{P_1} \right)_{cr} = \left( \frac{2}{n+1} \right)^{\frac{n}{n-1}}, \qquad
\frac{P_2}{P_1} \le \left( \frac{P_2}{P_1} \right)_{cr} \;\Rightarrow\; \text{초크 유동}
$$

- **SPC 질량 유량**: 비초크 시 (논문 식 (10)):
$$
\dot{m}_{\text{SPC}} = C_{d,\text{inj}} A_{\text{inj}} \sqrt{ 2 \rho_1 P_1 \left( \frac{n}{n-1} \right) \left[ \left( \frac{P_2}{P_1} \right)^{\frac{2}{n}} - \left( \frac{P_2}{P_1} \right)^{\frac{n+1}{n}} \right] }
$$
  초크 시 (논문 식 (12)):
$$
\dot{m}_{\text{SPC}} = C_{d,\text{inj}} A_{\text{inj}} \sqrt{ n \, \rho_1 P_1 \left( \frac{2}{n+1} \right)^{\frac{n+1}{n-1}} }
$$

- **HEM 질량 유량** (논문 식 (16)): 하류 상태는 등엔트로피 팽창($s_2 = s_1$)으로 결정됩니다. 초크 시에는 실제 후단 압력 $P_2$ 대신 **임계 압력 $P_{2,\text{eff}} = P_1 \cdot (P_2/P_1)_{cr}$에서의 등엔트로피 상태를 재계산**하여 사용합니다 (오리피스 목에서 유량이 고정되므로).
$$
\dot{m}_{\text{HEM}} = C_{d,\text{inj}} A_{\text{inj}} \, \rho_2 \sqrt{2 (h_1 - h_2)}
$$

- **Zivi 슬립비** (논문 식 (21)) 및 **하류 보이드율** (논문 식 (24)): 등엔트로피 건도 $x_2$와 슬립비 $S$로부터 하류 보이드율을 계산합니다.
$$
S = \left( \frac{\rho_{2,l}}{\rho_{2,v}} \right)^{\frac{1}{3}}
$$
$$
\alpha_2 = \frac{1}{1 + \dfrac{1 - x_2}{x_2} \, S \, \dfrac{\rho_{2,v}}{\rho_{2,l}}}
$$

- **FML 질량 유량 — 액상 유출** (논문 식 (22)): 하류가 대부분 증기이면($\alpha_2 \to 1$, 강한 플래싱) HEM이, 대부분 액체이면($\alpha_2 \to 0$) SPC가 지배합니다.
$$
\dot{m}_{\text{inj}} = (1 - \alpha_2) \cdot \dot{m}_{\text{SPC}} + \alpha_2 \cdot \dot{m}_{\text{HEM}}
$$

```matlab
% 초기화
mdot_SPC = 0;
mdot_HEM = 0;
mdot_inj = 0;
alpha2 = NaN;
S_slip = NaN;
is_choked = false;
critical_pressure_ratio = NaN;
pressure_ratio = NaN;

% 실기체 등엔트로피 지수 n (논문 식 (8)) - Helmholtz EOS에서 n = rho*c^2/P와 정확히 동치
% 상류 액상 상태 (T1, rho1)에서 액체 상 강제(state 0)로 음속을 조회하여 계산
Props1 = fluid.GetProps(T1, rho1, 0);
if isfinite(Props1.c) && Props1.c > 0 && isfinite(Props1.P) && Props1.P > 0
    n_isen = rho1 * Props1.c^2 / Props1.P;
else
    warning('Inj_FML_LiqFeed:IsenExpFallback', 'Sound speed lookup failed at (T1=%.2f K, rho1=%.2f kg/m^3). Falling back to n = cp/cv.', T1, rho1);
    n_isen = cp1 / cv1; % 폴백: 비열비 근사 (이상기체 극한)
end

deltaP = P1 - P2;

if deltaP > 0 && P1 > 0
    pressure_ratio = P2 / P1;

    % --- 초킹 판정 (SPC/HEM 공통 단일 기준, 식 (11)) ---
    if isfinite(n_isen) && n_isen > 1
        critical_pressure_ratio = (2 / (n_isen + 1))^(n_isen / (n_isen - 1));
        is_choked = (pressure_ratio <= critical_pressure_ratio);
    else
        warning('Inj_FML_LiqFeed:InvalidN', 'Invalid isentropic exponent n (%.3f). Falling back to SPI for single-phase term.', n_isen);
    end

    % --- SPC 질량 유량 (식 (10)/(12)) ---
    if isfinite(n_isen) && n_isen > 1
        if is_choked
            sqrt_term = n_isen * rho1 * P1 * (2 / (n_isen + 1))^((n_isen + 1) / (n_isen - 1));
        else
            sqrt_term = 2 * rho1 * P1 * (n_isen / (n_isen - 1)) * ...
                (pressure_ratio^(2 / n_isen) - pressure_ratio^((n_isen + 1) / n_isen));
        end
        if sqrt_term >= 0
            mdot_SPC = Cd_inj * A_inj * sqrt(sqrt_term);
        else
            warning('Inj_FML_LiqFeed:SPCSqrtNeg', 'Negative value in SPC sqrt. Setting mdot_SPC = 0.');
            mdot_SPC = 0;
        end
    else
        % n이 유효하지 않으면 SPI(비압축성)로 폴백 (Y = 1)
        mdot_SPC = Cd_inj * A_inj * sqrt(2 * rho1 * deltaP);
    end

    % --- 초크 시 하류 등엔트로피 상태 재계산 (P2_eff = P1 * 임계 압력비) ---
    if is_choked
        P2_eff = P1 * critical_pressure_ratio;
        try
            [rho2, h2, X2, rho2_l, rho2_v] = SolveIsentropicState(fluid, P2_eff, s1, T2_guess, rho2_guess);
        catch ME_state
            warning('Inj_FML_LiqFeed:ChokedStateFail', 'Failed to re-solve choked downstream state: %s. Using InjState values at P2.', ME_state.message);
        end
    end

    % --- HEM 질량 유량 (식 (16)) ---
    if h1 >= h2
        mdot_HEM = Cd_inj * A_inj * rho2 * sqrt(2 * (h1 - h2));
    else
        warning('Inj_FML_LiqFeed:NegativeEnthalpyDrop', 'h1 (%.2f J/kg) < h2 (%.2f J/kg) for HEM calculation. Setting mdot_HEM = 0.', h1, h2);
        mdot_HEM = 0;
    end

    % --- Zivi 슬립비 및 하류 보이드율 (식 (21), (24)) ---
    if ~isfinite(X2) || X2 <= 0
        alpha2 = 0; % 하류 전량 액체 -> 단상(SPC) 지배
    elseif X2 >= 1
        alpha2 = 1; % 하류 전량 증기 (완전 플래싱) -> HEM 지배
    elseif rho2_l > 0 && rho2_v > 0 && isfinite(rho2_l) && isfinite(rho2_v)
        S_slip = (rho2_l / rho2_v)^(1/3);
        alpha2 = 1 / (1 + ((1 - X2) / X2) * S_slip * (rho2_v / rho2_l));
    else
        warning('Inj_FML_LiqFeed:InvalidSatDensity', 'Invalid downstream saturation densities (rho2_l=%.2f, rho2_v=%.2f). Defaulting to HEM-dominant flow (alpha2=1).', rho2_l, rho2_v);
        alpha2 = 1; % Inj_NHNE_LiqFeed의 HEM 지배 폴백과 동일한 방침
    end

    % --- FML 질량 유량 (식 (22), 액상 유출) ---
    mdot_inj = (1 - alpha2) * mdot_SPC + alpha2 * mdot_HEM;

else
    % deltaP <= 0, no flow
    mdot_inj = 0;
    mdot_SPC = 0;
    mdot_HEM = 0;
    % alpha2, S_slip은 초기값 NaN 유지
end
```

# Output

| 명칭                    | 기호                        | 출력 변수           | 비고                                |
| --------------------- | ------------------------- | --------------- | --------------------------------- |
| 실기체 등엔트로피 지수           | $n$                       | x.inj.n_isen    | $\rho_1 c_1^2/P_1^{\text{EOS}}$ (식 (8)과 동치, EOS 음속 기반) |
| 임계 압력비                | $(P_2/P_1)_{cr}$          | x.inj.ratio_Pcr | 초킹 판정 기준 (식 (11))                 |
| 압력비                   | $P_2/P_1$                 | x.inj.ratio_P   |                                   |
| 초크 여부                 | —                         | x.inj.choked    | true: 초크 유동                       |
| Zivi 슬립비              | $S$                       | x.inj.S_slip    | $(\rho_{2,l}/\rho_{2,v})^{1/3}$   |
| 하류 보이드율               | $\alpha_2$                | x.inj.alpha2    | FML 가중치 (식 (24))                  |
| SPC 질량 유량 (Cd·A 포함)   | $\dot{m}_{\text{SPC}}$    | x.inj.mdot_SPC  |                                   |
| HEM 질량 유량 (Cd·A 포함)   | $\dot{m}_{\text{HEM}}$    | x.inj.mdot_HEM  | 초크 시 임계 압력 기준 상태로 계산              |
| FML 질량 유량             | $\dot{m}_{\text{inj}}$    | x.inj.mdot      | 식 (22) 가중 결과                      |

```matlab
x.inj.n_isen = n_isen;
x.inj.ratio_Pcr = critical_pressure_ratio;
x.inj.ratio_P = pressure_ratio;
x.inj.choked = is_choked;
x.inj.S_slip = S_slip;
x.inj.alpha2 = alpha2;
% Output the component mass flow rates *including* Cd*A
x.inj.mdot_SPC = mdot_SPC;
x.inj.mdot_HEM = mdot_HEM;
% Output the total calculated mass flow rate
x.inj.mdot = mdot_inj;
```

# 전체 코드
```matlab
function [x] = Inj_FML_LiqFeed(x)
%Inj_FML_LiqFeed  FML(Foletti-Magni-La Luna) 2상 질량 유량 모델 - 액상 유출
%   출처: La Luna et al., "A Two-Phase Mass Flow Rate Model for Nitrous
%   Oxide Based on Void Fraction", Aerospace 2022, 9(12), 828. (식 (22))
%   선행 조건: InjState_LiqFeed가 먼저 호출되어 하류 등엔트로피 상태가
%   x.inj.*에 준비되어 있어야 함.

%% Input
fluid = x.fluid;
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_FML_LiqFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_FML_LiqFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho1 = x.tank.rho_l;
h1 = x.tank.h_l;
s1 = x.tank.s_l;
T1 = x.tank.T;     % 상류 음속 조회용 (n 정확 계산)
cp1 = x.tank.cp_l; % n 폴백 근사용
cv1 = x.tank.cv_l; % n 폴백 근사용

% 하류 등엔트로피 상태 (InjState_LiqFeed가 먼저 호출되어 있어야 함)
rho2 = x.inj.rho;
h2 = x.inj.h;
X2 = x.inj.X;         % 하류 건도 (등엔트로피 팽창 기준)
rho2_l = x.inj.rho_l; % 하류 포화 액상 밀도
rho2_v = x.inj.rho_v; % 하류 포화 증기상 밀도
T2_guess = x.inj.T;   % 초크 시 재계산용 초기 추정값
rho2_guess = x.inj.rho;

A_inj = x.inj.A;
Cd_inj = x.inj.Cd;

%% System
% 초기화
mdot_SPC = 0;
mdot_HEM = 0;
mdot_inj = 0;
alpha2 = NaN;
S_slip = NaN;
is_choked = false;
critical_pressure_ratio = NaN;
pressure_ratio = NaN;

% 실기체 등엔트로피 지수 n (논문 식 (8)) - Helmholtz EOS에서 n = rho*c^2/P와 정확히 동치
% 상류 액상 상태 (T1, rho1)에서 액체 상 강제(state 0)로 음속을 조회하여 계산
Props1 = fluid.GetProps(T1, rho1, 0);
if isfinite(Props1.c) && Props1.c > 0 && isfinite(Props1.P) && Props1.P > 0
    n_isen = rho1 * Props1.c^2 / Props1.P;
else
    warning('Inj_FML_LiqFeed:IsenExpFallback', 'Sound speed lookup failed at (T1=%.2f K, rho1=%.2f kg/m^3). Falling back to n = cp/cv.', T1, rho1);
    n_isen = cp1 / cv1; % 폴백: 비열비 근사 (이상기체 극한)
end

deltaP = P1 - P2;

if deltaP > 0 && P1 > 0
    pressure_ratio = P2 / P1;

    % --- 초킹 판정 (SPC/HEM 공통 단일 기준, 식 (11)) ---
    if isfinite(n_isen) && n_isen > 1
        critical_pressure_ratio = (2 / (n_isen + 1))^(n_isen / (n_isen - 1));
        is_choked = (pressure_ratio <= critical_pressure_ratio);
    else
        warning('Inj_FML_LiqFeed:InvalidN', 'Invalid isentropic exponent n (%.3f). Falling back to SPI for single-phase term.', n_isen);
    end

    % --- SPC 질량 유량 (식 (10)/(12)) ---
    if isfinite(n_isen) && n_isen > 1
        if is_choked
            sqrt_term = n_isen * rho1 * P1 * (2 / (n_isen + 1))^((n_isen + 1) / (n_isen - 1));
        else
            sqrt_term = 2 * rho1 * P1 * (n_isen / (n_isen - 1)) * ...
                (pressure_ratio^(2 / n_isen) - pressure_ratio^((n_isen + 1) / n_isen));
        end
        if sqrt_term >= 0
            mdot_SPC = Cd_inj * A_inj * sqrt(sqrt_term);
        else
            warning('Inj_FML_LiqFeed:SPCSqrtNeg', 'Negative value in SPC sqrt. Setting mdot_SPC = 0.');
            mdot_SPC = 0;
        end
    else
        % n이 유효하지 않으면 SPI(비압축성)로 폴백 (Y = 1)
        mdot_SPC = Cd_inj * A_inj * sqrt(2 * rho1 * deltaP);
    end

    % --- 초크 시 하류 등엔트로피 상태 재계산 (P2_eff = P1 * 임계 압력비) ---
    if is_choked
        P2_eff = P1 * critical_pressure_ratio;
        try
            [rho2, h2, X2, rho2_l, rho2_v] = SolveIsentropicState(fluid, P2_eff, s1, T2_guess, rho2_guess);
        catch ME_state
            warning('Inj_FML_LiqFeed:ChokedStateFail', 'Failed to re-solve choked downstream state: %s. Using InjState values at P2.', ME_state.message);
        end
    end

    % --- HEM 질량 유량 (식 (16)) ---
    if h1 >= h2
        mdot_HEM = Cd_inj * A_inj * rho2 * sqrt(2 * (h1 - h2));
    else
        warning('Inj_FML_LiqFeed:NegativeEnthalpyDrop', 'h1 (%.2f J/kg) < h2 (%.2f J/kg) for HEM calculation. Setting mdot_HEM = 0.', h1, h2);
        mdot_HEM = 0;
    end

    % --- Zivi 슬립비 및 하류 보이드율 (식 (21), (24)) ---
    if ~isfinite(X2) || X2 <= 0
        alpha2 = 0; % 하류 전량 액체 -> 단상(SPC) 지배
    elseif X2 >= 1
        alpha2 = 1; % 하류 전량 증기 (완전 플래싱) -> HEM 지배
    elseif rho2_l > 0 && rho2_v > 0 && isfinite(rho2_l) && isfinite(rho2_v)
        S_slip = (rho2_l / rho2_v)^(1/3);
        alpha2 = 1 / (1 + ((1 - X2) / X2) * S_slip * (rho2_v / rho2_l));
    else
        warning('Inj_FML_LiqFeed:InvalidSatDensity', 'Invalid downstream saturation densities (rho2_l=%.2f, rho2_v=%.2f). Defaulting to HEM-dominant flow (alpha2=1).', rho2_l, rho2_v);
        alpha2 = 1; % Inj_NHNE_LiqFeed의 HEM 지배 폴백과 동일한 방침
    end

    % --- FML 질량 유량 (식 (22), 액상 유출) ---
    mdot_inj = (1 - alpha2) * mdot_SPC + alpha2 * mdot_HEM;

else
    % deltaP <= 0, no flow
    mdot_inj = 0;
    mdot_SPC = 0;
    mdot_HEM = 0;
    % alpha2, S_slip은 초기값 NaN 유지
end

%% Output
x.inj.n_isen = n_isen;
x.inj.ratio_Pcr = critical_pressure_ratio;
x.inj.ratio_P = pressure_ratio;
x.inj.choked = is_choked;
x.inj.S_slip = S_slip;
x.inj.alpha2 = alpha2;
% Output the component mass flow rates *including* Cd*A
x.inj.mdot_SPC = mdot_SPC;
x.inj.mdot_HEM = mdot_HEM;
% Output the total calculated mass flow rate
x.inj.mdot = mdot_inj;

end

function [rho2, h2, X2, rho2_l, rho2_v] = SolveIsentropicState(fluid, P_target, s1, guessT, guessRho)
%SolveIsentropicState  목표 압력 P_target까지의 등엔트로피 팽창 상태 계산
%   초크 조건에서 임계 압력 기준의 하류 상태를 구하기 위해 사용.
%   (InjState_LiqFeed와 동일한 lsqnonlin 방식)
pFunc = @(v) [ getfield(fluid.GetProps(v(1), v(2)), 'P') - P_target;
               getfield(fluid.GetProps(v(1), v(2)), 's') - s1 ];
lb = [183, 2.7];
ub = [309, 1236];
v = lsqnonlin(pFunc, [guessT, guessRho], lb, ub, optimset('Display', 'off', 'TolFun', 1e-10));
Props = fluid.GetProps(v(1), v(2), 1);
rho2 = Props.rho;
h2 = Props.h;
X2 = Props.X;
rho2_l = Props.rho_l;
rho2_v = Props.rho_v;
end
```
