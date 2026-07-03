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
	3. **초킹 처리**: SPC는 식 (11)의 자체 임계 압력비로, **HEM은 등엔트로피 팽창 경로 위 질량 플럭스의 최대점(2상 초크점)을 수치 탐색**하여 각각 초크 캡을 적용 (논문 4.3절 방식). 두 항의 초크점이 크게 다르기 때문에(액상 SPC 임계비 ~0.03 vs HEM 초크점 ~0.75) 공통 임계비를 쓰면 HEM 캡이 무력화되어 콜드플로우 유량을 크게 과소 예측함 — 2026 수류시험 검증에서 확인.
- 액상 유출 시 가중식 (논문 식 (22)): 하류에서 플래싱이 강할수록($\alpha_2 \to 1$) HEM 기여가 커지고, 액상이 유지될수록($\alpha_2 \to 0$) SPC 기여가 커집니다.
- **선행 조건**: `InjState_LiqFeed.m`이 먼저 호출되어 하류 등엔트로피 상태(`x.inj.rho`, `x.inj.h`, `x.inj.X`, `x.inj.rho_l`, `x.inj.rho_v`)가 계산되어 있어야 합니다. (`Save_Input_Config.m`의 `u.inj.model_LiqFeed`에 **"FML"** 키워드를 포함해 지정하면 `System/LiqFeed.m`의 모델 분기에서 호출됨)
- 인젝터 입구가 탱크 출구에 바로 연결되어있다는 조건을 적용하였다. (배관 라인 무시 → 실측 비교 시 배관 손실은 유효 $C_d$에 흡수됨)
# Input

| 명칭            | 기호               | 입력 변수         | 비고                                       |
| ------------- | ---------------- | ------------- | ---------------------------------------- |
| 인젝터 상류 압력     | $P_1$            | x.tank.P      | 인젝터 상부 압력                                |
| 인젝터 후단 압력     | $P_2$            | x.comb.Pinj   | 인젝터 하류 압력 (기본). 유효하지 않으면 x.comb.P 사용     |
| 연소실 압력        | $P_c$            | x.comb.P      | 인젝터 하류 압력 (대체)                           |
| 인젝터 상류 액상 밀도  | $\rho_1$         | x.tank.rho_l  | 상류 밀도 (탱크 액체 상의 밀도)                      |
| 인젝터 상류 엔탈피    | $h_1$            | x.tank.h_l    | 상류 액상 엔탈피 (HEM 플럭스 계산 기준)                |
| 인젝터 상류 엔트로피   | $s_1$            | x.tank.s_l    | 등엔트로피 팽창 경로 정의 (초크점 탐색에 사용)              |
| 탱크 온도         | $T_1$            | x.tank.T      | 상류 음속 조회(EOS 액체 강제 호출) 및 탐색 솔버 초기 추정값    |
| 상류 액상 정압 비열   | $c_{p,l}$        | x.tank.cp_l   | $n$ 폴백 근사($c_{p,l}/c_{v,l}$)에 사용            |
| 상류 액상 정적 비열   | $c_{v,l}$        | x.tank.cv_l   | $n$ 폴백 근사($c_{p,l}/c_{v,l}$)에 사용            |
| 하류 혼합 밀도      | $\rho_2$         | x.inj.rho     | `InjState_LiqFeed` 계산 결과 (P₂ 등엔트로피 상태)   |
| 하류 혼합 엔탈피     | $h_2$            | x.inj.h       | `InjState_LiqFeed` 계산 결과                 |
| 하류 건도         | $x_2$            | x.inj.X       | `InjState_LiqFeed` 계산 결과 (등엔트로피 건도)      |
| 하류 포화 액상 밀도   | $\rho_{2,l}$     | x.inj.rho_l   | 슬립비·보이드율 계산에 사용                          |
| 하류 포화 증기상 밀도  | $\rho_{2,v}$     | x.inj.rho_v   | 슬립비·보이드율 계산에 사용                          |
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
T1 = x.tank.T;     % 상류 음속 조회 및 초크점 탐색 솔버 초기 추정값
cp1 = x.tank.cp_l; % n 폴백 근사용
cv1 = x.tank.cv_l; % n 폴백 근사용

% 하류(P2) 등엔트로피 상태 (InjState_LiqFeed 결과) - alpha2 및 비초크 HEM에 사용
rho2 = x.inj.rho;
h2 = x.inj.h;
X2 = x.inj.X;         % 하류 건도 (등엔트로피 팽창 기준)
rho2_l = x.inj.rho_l; % 하류 포화 액상 밀도
rho2_v = x.inj.rho_v; % 하류 포화 증기상 밀도

A_inj = x.inj.A;
Cd_inj = x.inj.Cd;
```

# System
- **실기체 등엔트로피 지수** $n$ (논문 식 (8), **SPC 항 전용**):
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
  즉 식 (8)의 $n$은 실기체 등엔트로피 지수 $\rho c^2 / P$와 **정확히 동치**이므로, EOS가 이미 출력하는 음속 $c$로 정확하게 계산합니다. 상류 액상 상태 $(T_1, \rho_1)$에서 자기일관되게 평가하며(액체 상 강제 조회), 음속 조회에 실패하면 비열비 근사 $n \approx c_{p,l}/c_{v,l}$로 폴백합니다.
  ⚠️ 이 $n$은 **SPC 항의 유량식·임계비에만** 사용합니다. 액상의 $n$은 매우 커서($\sim 50{+}$) 식 (11)의 임계비가 ~0.03까지 내려가는데, 이를 HEM 캡 기준으로 함께 쓰면 HEM 초크 캡이 사실상 무력화되어 유량을 크게 과소 예측합니다 (아래 HEM 항 참조).

- **SPC 질량 유량** (식 (10), 초크 시 식 (12); 자체 임계비 식 (11)로 판정):
$$
\left( \frac{P_2}{P_1} \right)_{cr} = \left( \frac{2}{n+1} \right)^{\frac{n}{n-1}}
$$
$$
\dot{m}_{\text{SPC}} = C_{d,\text{inj}} A_{\text{inj}} \sqrt{ 2 \rho_1 P_1 \left( \frac{n}{n-1} \right) \left[ \left( \frac{P_2}{P_1} \right)^{\frac{2}{n}} - \left( \frac{P_2}{P_1} \right)^{\frac{n+1}{n}} \right] }
\;\xrightarrow{\text{초크}}\;
C_{d,\text{inj}} A_{\text{inj}} \sqrt{ n \, \rho_1 P_1 \left( \frac{2}{n+1} \right)^{\frac{n+1}{n-1}} }
$$

- **Zivi 슬립비** (식 (21)) 및 **하류 보이드율** (식 (24)): 가중치 $\alpha_2$는 **실제 하류 압력 $P_2$까지의 등엔트로피 팽창 상태**(= `InjState_LiqFeed` 결과)로 평가합니다. $\alpha_2$는 "출구 유동이 얼마나 기화되는가"를 나타내는 가중치이므로 논문 문면(5장) 그대로 하류 상태 기준이며, 초킹 캡은 아래처럼 HEM 항 자체에 겁니다.
$$
S = \left( \frac{\rho_{2,l}}{\rho_{2,v}} \right)^{\frac{1}{3}}, \qquad
\alpha_2 = \frac{1}{1 + \dfrac{1 - x_2}{x_2} \, S \, \dfrac{\rho_{2,v}}{\rho_{2,l}}}
$$

- **HEM 질량 유량 + 2상 초크 캡** (식 (16) + 논문 4.3절): HEM 질량 플럭스
$$
G_{\text{HEM}}(P_e) = \rho_2(P_e) \sqrt{2\,(h_1 - h_2(P_e))}, \qquad s_2 = s_1
$$
  는 팽창 압력 $P_e$에 대해 **내부 최대점(2상 초크점)** 을 가지며 ($P_e \to P_1$이면 엔탈피 낙차 소멸, $P_e \to 0$이면 밀도 폭락으로 양쪽 끝에서 0), 그 이하로 팽창하면 플럭스가 오히려 감소합니다. 물리적으로는 초크점에서 유량이 고정되므로:
$$
\dot{m}_{\text{HEM}} = C_{d,\text{inj}} A_{\text{inj}} \cdot G_{\text{HEM}}\big(\max(P_2,\; r_{choke} P_1)\big),
\qquad r_{choke} = \arg\max_r G_{\text{HEM}}(r P_1)
$$
  - $r_{choke}$는 **황금분할 탐색**으로 찾습니다 (단봉 함수). 각 평가는 등엔트로피 상태 1회 해석 — CoolProp 물성 모델이면 내장 P–s 플래시, 인하우스면 lsqnonlin 역산.
  - **캐시**: 초크점은 상류 상태 $(P_1, s_1)$만의 함수이므로, 상류가 일정 비율(인하우스 0.5%, CoolProp 0.1%) 이상 변할 때만 재탐색하고 그 사이에는 직전 결과를 재사용합니다 (연소 모드의 Pc 반복 루프에서는 스텝당 최대 1회 탐색).
  - **해 검증**: 등엔트로피 솔버는 잔차(무차원화)와 경계 밀착 여부를 검사하여, 가짜 근(예: 밀도 상한에 붙은 액체급 해)이 유량 계산에 쓰이지 않도록 `valid` 플래그로 걸러냅니다.
  - 참고: 포화액 N₂O의 2상 초크점은 통상 $P_2/P_1 \approx 0.7{\sim}0.8$ 부근입니다 (2026 수류시험 조건 4.5°C에서 0.75).

- **FML 질량 유량 — 액상 유출** (논문 식 (22)):
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
hem_choked = false;
critical_pressure_ratio = NaN; % SPC 임계 압력비 (식 (11))
r_choke_HEM = NaN;             % HEM 플럭스 최대점 압력비 (2상 초크점, 수치 탐색)
pressure_ratio = NaN;

% 실기체 등엔트로피 지수 n (논문 식 (8)) - Helmholtz EOS에서 n = rho*c^2/P와 정확히 동치
% 상류 액상 상태 (T1, rho1)에서 액체 상 강제(state 0)로 음속을 조회하여 계산 (SPC 항 전용)
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

    % --- SPC 질량 유량 (식 (10)/(12), 자체 임계비 식 (11)로 초크 판정) ---
    if isfinite(n_isen) && n_isen > 1
        critical_pressure_ratio = (2 / (n_isen + 1))^(n_isen / (n_isen - 1));
        if pressure_ratio <= critical_pressure_ratio
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
        warning('Inj_FML_LiqFeed:InvalidN', 'Invalid isentropic exponent n (%.3f). Falling back to SPI for single-phase term.', n_isen);
        mdot_SPC = Cd_inj * A_inj * sqrt(2 * rho1 * deltaP);
    end

    % --- Zivi 슬립비 및 하류 보이드율 (식 (21), (24)) ---
    % 가중치 alpha2는 실제 하류 압력 P2까지의 등엔트로피 팽창 상태로 평가
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

    % --- HEM 질량 유량 (식 (16)) + 2상 초크 캡 (논문 4.3절 방식) ---
    [r_choke_HEM, choke_state] = FindHEMChokeRatio(fluid, P1, s1, h1, T1, rho1);
    if isfinite(r_choke_HEM) && pressure_ratio < r_choke_HEM && choke_state.valid
        hem_choked = true;
        rho2_HEM = choke_state.rho; % 2상 초크점 상태로 캡
        h2_HEM = choke_state.h;
    else
        rho2_HEM = rho2; % 비초크: 실제 하류(P2) 상태 (InjState 결과)
        h2_HEM = h2;
        if ~isfinite(r_choke_HEM)
            warning('Inj_FML_LiqFeed:HEMChokeSearchFail', 'HEM choke-point search failed. Using downstream (P2) state without cap.');
        end
    end
    if h1 >= h2_HEM
        mdot_HEM = Cd_inj * A_inj * rho2_HEM * sqrt(2 * (h1 - h2_HEM));
    else
        warning('Inj_FML_LiqFeed:NegativeEnthalpyDrop', 'h1 (%.2f J/kg) < h2 (%.2f J/kg) for HEM calculation. Setting mdot_HEM = 0.', h1, h2_HEM);
        mdot_HEM = 0;
    end

    % --- FML 질량 유량 (식 (22), 액상 유출) ---
    mdot_inj = (1 - alpha2) * mdot_SPC + alpha2 * mdot_HEM;

else
    % deltaP <= 0, no flow
    mdot_inj = 0;
    mdot_SPC = 0;
    mdot_HEM = 0;
    % alpha2, S_slip, r_choke_HEM은 초기값 NaN 유지
end
```

# Output

| 명칭                    | 기호                        | 출력 변수               | 비고                                |
| --------------------- | ------------------------- | ------------------- | --------------------------------- |
| 실기체 등엔트로피 지수           | $n$                       | x.inj.n_isen        | $\rho_1 c_1^2/P_1^{\text{EOS}}$ (식 (8)과 동치, SPC 전용) |
| SPC 임계 압력비            | $(P_2/P_1)_{cr}$          | x.inj.ratio_Pcr     | 식 (11), SPC 항 초크 판정 기준             |
| HEM 2상 초크점 압력비        | $r_{choke}$               | x.inj.ratio_Pcr_HEM | HEM 플럭스 최대점 (수치 탐색)                |
| 압력비                   | $P_2/P_1$                 | x.inj.ratio_P       |                                   |
| HEM 초크 캡 작동 여부        | —                         | x.inj.choked        | true: 배압이 HEM 초크점 아래 → 캡 적용        |
| Zivi 슬립비              | $S$                       | x.inj.S_slip        | $(\rho_{2,l}/\rho_{2,v})^{1/3}$   |
| 하류 보이드율               | $\alpha_2$                | x.inj.alpha2        | FML 가중치 (식 (24), P₂ 상태 기준)         |
| SPC 질량 유량 (Cd·A 포함)   | $\dot{m}_{\text{SPC}}$    | x.inj.mdot_SPC      |                                   |
| HEM 질량 유량 (Cd·A 포함)   | $\dot{m}_{\text{HEM}}$    | x.inj.mdot_HEM      | 2상 초크점에서 캡 적용                      |
| FML 질량 유량             | $\dot{m}_{\text{inj}}$    | x.inj.mdot          | 식 (22) 가중 결과                      |

```matlab
x.inj.n_isen = n_isen;
x.inj.ratio_Pcr = critical_pressure_ratio; % SPC 임계 압력비 (식 (11))
x.inj.ratio_Pcr_HEM = r_choke_HEM;         % HEM 2상 초크점 압력비 (수치 탐색)
x.inj.ratio_P = pressure_ratio;
x.inj.choked = hem_choked;                 % HEM 캡 작동 여부 (지배 항 기준의 초킹)
x.inj.S_slip = S_slip;
x.inj.alpha2 = alpha2;
% Output the component mass flow rates *including* Cd*A
x.inj.mdot_SPC = mdot_SPC;
x.inj.mdot_HEM = mdot_HEM;
% Output the total calculated mass flow rate
x.inj.mdot = mdot_inj;
```

# 전체 코드
전체 구현은 [Inj_FML_LiqFeed.m](Inj_FML_LiqFeed.m) 참조. 위 Input/System/Output 코드에 더해 두 개의 로컬 함수를 포함합니다:

- `FindHEMChokeRatio(fluid, P1, s1, h1, guessT, guessRho)` — HEM 질량 플럭스 최대점(2상 초크점) 압력비를 황금분할 탐색으로 찾고, 상류 상태 $(P_1, s_1)$가 직전 호출 대비 허용 오차(인하우스 0.5%, CoolProp 0.1%) 이내면 캐시(persistent)를 재사용. 유효한 결과만 캐시에 저장.
- `SolveIsentropicState(fluid, P_target, s_target, guessT, guessRho)` — 목표 압력까지의 등엔트로피 상태 계산. CoolProp 물성 모델이면 내장 P–s 플래시(`GetPropsPS`)를 사용하고(가짜 근 원천 차단), 인하우스면 lsqnonlin 역산(`InjState_LiqFeed`와 동일 방식)에 잔차 무차원화 + 해 검증(잔차/경계 밀착 감지)을 적용하여 가짜 근을 걸러냄.
