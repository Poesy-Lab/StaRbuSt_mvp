---
tags:
  - 2상유동
  - 인젝터
  - FML
  - ChokedFlow
Author: SRS 33기 박호진
---
# 소개
- `Inj_NHNE_VapFeed.m`은 **탱크 상단 출구에서 증기상의 유출이 일어날 때, 인젝터에서의 질량 유량**을 FML(Foletti–Magni–La Luna) 모델의 증기상 유출 식으로 계산하는 함수입니다.
- 출처: S. La Luna, N. Foletti, L. Magni, D. Zuin, F. Maggi, *"A Two-Phase Mass Flow Rate Model for Nitrous Oxide Based on Void Fraction"*, Aerospace 2022, 9(12), 828. ([로컬 사본](../../docs/paper/2022_LaLuna/2022_LaLuna.md))
- FML은 일반화 NHNE(Non-Homogeneous Non-Equilibrium) 계열의 모델로, 본 파일은 그 중 **증기상 배출(vapor phase draining) 가중식 (논문 식 (23))**을 구현합니다. (액상 유출용 짝 문서: `Inj_FML_LiqFeed.md`)
- 액상 유출 식 (22)과 가중이 **반전**되어 있습니다: 하류에서 증기가 유지될수록($\alpha_2 \to 1$) 단상 압축성(SPC) 항이 지배하고, 팽창 중 응축으로 액적이 생길수록($\alpha_2 \to 0$) 2상(HEM) 항의 기여가 커집니다. 논문의 실험에서 증기 배출 시 $\alpha_2$는 항상 1에 가깝게 유지되어 물리적 타당성이 확인되었습니다.
- **초킹 처리**: SPC는 식 (11)의 자체 임계 압력비로, HEM은 등엔트로피 팽창 경로 위 질량 플럭스의 최대점(초크점)을 수치 탐색하여 각각 초크 캡을 적용합니다 (논문 4.3절 방식, `Inj_FML_LiqFeed`와 동일 구조).
- 기존 `Inj_ICF_VapFeed.m`(등엔트로피 초크 유동, 이상기체 $\gamma$ 사용)과의 관계: FML의 SPC 항은 ICF와 같은 형태이나 비열비 $\gamma$ 대신 **실기체 등엔트로피 지수 $n$**을 사용하며, 여기에 HEM 기여와 보이드율 가중이 추가된 상위 모델입니다.
- **선행 조건**: `InjState_VapFeed.m`이 먼저 호출되어 하류 등엔트로피 상태(`x.inj.rho`, `x.inj.h`, `x.inj.X`, `x.inj.rho_l`, `x.inj.rho_v`)가 계산되어 있어야 합니다. (`Save_Input_Config.m`의 `u.inj.model_VapFeed`에 **"NHNE"** 키워드를 포함해 지정하면 `System/VapFeed.m`의 모델 분기에서 호출됨)
- 인젝터를 통한 열전달은 고려되지 않았다.
- 인젝터 입구 상류 조건: 기본은 탱크 직결(배관 라인 무시)이나, **급기 라인 결합 모드**(`u.feed.mode = 1`, CoolProp 물성)에서는 라인 출구 상태를 상류로 사용한다 (아래 참조).

## 급기 라인 결합 (u.feed.mode = 1)
- 액체 소진 후에도 탱크 포화증기는 같은 급기 라인을 지나므로, `Feed_Line(x, mdot, 'vap')`(h = h_v 보존 균질 행진)과 **유량 이분법**으로 결합합니다 — `Inj_HEMc_LiqFeed`의 액상 결합과 동일한 구조.
- 상류 엔트로피는 라인 출구 (P_out, h_v)의 포화 지렛대로 재평가되어 **라인 마찰의 엔트로피 생성이 자동 반영**됩니다. 증기 유동은 속도가 커서 라인 압손이 액상보다 훨씬 크며(수~10 bar 이상), 그만큼 증기 배출 유량이 직결 대비 크게 줄어 꼬리(tail)가 길어집니다.
- 결합 경로의 물성은 `N2O_SatTable` 지렛대 전용(핫루프 py 호출 없음), HEM 초크 캡도 지렛대 플럭스의 황금분할 탐색으로 처리합니다. 실기체 등엔트로피 지수 $n$은 스텝당 탱크 상태에서 1회 평가한 값을 재사용합니다 (라인 압손 구간에서 변화 미미). 과열 영역은 X ≤ 1 클램프로 포화증기 근사 (증기상은 $\alpha_2 \approx 1$이라 SPC 지배적 — 근사 영향 미미).
- 무손실(탱크 직결) 유량을 이분법 상한으로 사용하며, 브래킷 실패(라인 손실이 무시할 수준) 시 직결 값을 유지합니다. 수렴 결과는 `x.feed.P_out / x_out / dP_line`으로 저장되어 `y.feed.*`에 로깅됩니다.
# Input

| 명칭            | 기호               | 입력 변수         | 비고                                       |
| ------------- | ---------------- | ------------- | ---------------------------------------- |
| 탱크 내부 압력      | $P_1$            | x.tank.P      | 인젝터 상류 압력                                |
| 인젝터 후단 압력     | $P_2$            | x.comb.Pinj   | 인젝터 하류 압력 (기본). 유효하지 않으면 x.comb.P 사용     |
| 연소실 압력        | $P_c$            | x.comb.P      | 인젝터 하류 압력 (대체)                           |
| 탱크 내부 증기상 밀도  | $\rho_1$         | x.tank.rho_v  | 상류 밀도 (탱크 증기 상의 밀도)                      |
| 상류 증기상 엔탈피    | $h_1$            | x.tank.h_v    | HEM 플럭스 계산 기준                            |
| 상류 증기상 엔트로피   | $s_1$            | x.tank.s_v    | 등엔트로피 팽창 경로 정의 (초크점 탐색에 사용)              |
| 탱크 온도         | $T_1$            | x.tank.T      | 상류 음속 조회(EOS 기체 강제 호출) 및 탐색 솔버 초기 추정값    |
| 증기상 정압 비열     | $c_{p,v}$        | x.tank.cp_v   | $n$ 폴백 근사($c_{p,v}/c_{v,v}$)에 사용            |
| 증기상 정적 비열     | $c_{v,v}$        | x.tank.cv_v   | $n$ 폴백 근사($c_{p,v}/c_{v,v}$)에 사용            |
| 하류 혼합 밀도      | $\rho_2$         | x.inj.rho     | `InjState_VapFeed` 계산 결과 (P₂ 등엔트로피 상태)   |
| 하류 혼합 엔탈피     | $h_2$            | x.inj.h       | `InjState_VapFeed` 계산 결과                 |
| 하류 건도         | $x_2$            | x.inj.X       | `InjState_VapFeed` 계산 결과 (등엔트로피 건도)      |
| 하류 포화 액상 밀도   | $\rho_{2,l}$     | x.inj.rho_l   | 슬립비·보이드율 계산에 사용                          |
| 하류 포화 증기상 밀도  | $\rho_{2,v}$     | x.inj.rho_v   | 슬립비·보이드율 계산에 사용                          |
| 인젝터 출구 면적     | $A_{\text{inj}}$ | x.inj.A       |                                          |
| 인젝터 유량 계수     | $C_{d,\text{inj}}$ | x.inj.Cd    |                                          |

```matlab
fluid = x.fluid;
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_NHNE_VapFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_NHNE_VapFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho1 = x.tank.rho_v;
h1 = x.tank.h_v;
s1 = x.tank.s_v;
T1 = x.tank.T;     % 상류 음속 조회 및 초크점 탐색 솔버 초기 추정값
cpv = x.tank.cp_v; % n 폴백 근사용
cvv = x.tank.cv_v; % n 폴백 근사용

% 하류(P2) 등엔트로피 상태 (InjState_VapFeed 결과) - alpha2 및 비초크 HEM에 사용
rho2 = x.inj.rho;
h2 = x.inj.h;
X2 = x.inj.X;         % 하류 건도 (등엔트로피 팽창 기준)
rho2_l = x.inj.rho_l; % 하류 포화 액상 밀도
rho2_v = x.inj.rho_v; % 하류 포화 증기상 밀도

A_inj = x.inj.A;
Cd_inj = x.inj.Cd;
```

# System
- **실기체 등엔트로피 지수** $n$ (논문 식 (8), **SPC 항 전용**): `Inj_FML_LiqFeed.md`의 유도와 동일하게 $n = \rho c^2/P$로 정확 계산합니다 (기체 상 강제 조회). 음속 조회 실패 시 $n \approx c_{p,v}/c_{v,v}$로 폴백하며, 이상기체 극한에서는 $n \to \gamma$가 되어 SPC 항이 기존 ICF 모델과 일치합니다.
$$
n = \frac{\rho_1 \, c_1^2}{P_1^{\text{EOS}}}, \qquad c_1 = c \big|_{(T_1, \rho_1),\, \text{기체 강제}}
$$

- **SPC 질량 유량** (식 (10), 초크 시 식 (12); 자체 임계비 식 (11)로 판정):
$$
\left( \frac{P_2}{P_1} \right)_{cr} = \left( \frac{2}{n+1} \right)^{\frac{n}{n-1}}
$$
$$
\dot{m}_{\text{SPC}} = C_{d,\text{inj}} A_{\text{inj}} \sqrt{ 2 \rho_1 P_1 \left( \frac{n}{n-1} \right) \left[ \left( \frac{P_2}{P_1} \right)^{\frac{2}{n}} - \left( \frac{P_2}{P_1} \right)^{\frac{n+1}{n}} \right] }
\;\xrightarrow{\text{초크}}\;
C_{d,\text{inj}} A_{\text{inj}} \sqrt{ n \, \rho_1 P_1 \left( \frac{2}{n+1} \right)^{\frac{n+1}{n-1}} }
$$

- **Zivi 슬립비** (식 (21)) 및 **하류 보이드율** (식 (24)): 가중치 $\alpha_2$는 실제 하류 압력 $P_2$까지의 등엔트로피 팽창 상태(= `InjState_VapFeed` 결과)로 평가합니다. 증기상 유출에서는 일반적으로 $x_2 \approx 1$이므로 $\alpha_2 \approx 1$이 되어 총 유량은 사실상 SPC 항이 결정합니다.
$$
S = \left( \frac{\rho_{2,l}}{\rho_{2,v}} \right)^{\frac{1}{3}}, \qquad
\alpha_2 = \frac{1}{1 + \dfrac{1 - x_2}{x_2} \, S \, \dfrac{\rho_{2,v}}{\rho_{2,l}}}
$$

- **HEM 질량 유량 + 초크 캡** (식 (16) + 논문 4.3절): HEM 질량 플럭스 $G_{\text{HEM}}(P_e) = \rho_2(P_e)\sqrt{2(h_1 - h_2(P_e))}$의 최대점(초크점)을 황금분할 탐색으로 찾고, 배압이 그보다 낮으면 초크점 상태로 HEM을 평가합니다. 상류 상태 $(P_1, s_1)$가 0.5% 이내로 유지되면 직전 탐색 결과를 캐시로 재사용하며, 등엔트로피 솔버의 해 검증(잔차 + 경계 밀착 감지)으로 가짜 근(예: 밀도 상한에 붙은 액체급 해)을 걸러냅니다 — 탱크 소진 직전 구간에서 발생하던 mdot_HEM 진단값 폭주의 원인이 이것이었습니다.
$$
\dot{m}_{\text{HEM}} = C_{d,\text{inj}} A_{\text{inj}} \cdot G_{\text{HEM}}\big(\max(P_2,\; r_{choke} P_1)\big),
\qquad r_{choke} = \arg\max_r G_{\text{HEM}}(r P_1)
$$

- **FML 질량 유량 — 증기상 유출** (논문 식 (23)): 액상 유출 식 (22)과 가중이 반전됩니다.
$$
\dot{m}_{\text{inj}} = \alpha_2 \cdot \dot{m}_{\text{SPC}} + (1 - \alpha_2) \cdot \dot{m}_{\text{HEM}}
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
r_choke_HEM = NaN;             % HEM 플럭스 최대점 압력비 (초크점, 수치 탐색)
pressure_ratio = NaN;

% 실기체 등엔트로피 지수 n (논문 식 (8)) - Helmholtz EOS에서 n = rho*c^2/P와 정확히 동치
% 상류 증기상 상태 (T1, rho1)에서 기체 상 강제(state 2)로 음속을 조회하여 계산 (SPC 항 전용)
Props1 = fluid.GetProps(T1, rho1, 2);
if isfinite(Props1.c) && Props1.c > 0 && isfinite(Props1.P) && Props1.P > 0
    n_isen = rho1 * Props1.c^2 / Props1.P;
else
    warning('Inj_NHNE_VapFeed:IsenExpFallback', 'Sound speed lookup failed at (T1=%.2f K, rho1=%.2f kg/m^3). Falling back to n = cp/cv.', T1, rho1);
    n_isen = cpv / cvv; % 폴백: 비열비 근사 (이상기체 극한, ICF와 동일)
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
            warning('Inj_NHNE_VapFeed:SPCSqrtNeg', 'Negative value in SPC sqrt. Setting mdot_SPC = 0.');
            mdot_SPC = 0;
        end
    else
        % n이 유효하지 않으면 SPI(비압축성)로 폴백 (Y = 1)
        warning('Inj_NHNE_VapFeed:InvalidN', 'Invalid isentropic exponent n (%.3f). Falling back to SPI for single-phase term.', n_isen);
        mdot_SPC = Cd_inj * A_inj * sqrt(2 * rho1 * deltaP);
    end

    % --- Zivi 슬립비 및 하류 보이드율 (식 (21), (24)) ---
    % 가중치 alpha2는 실제 하류 압력 P2까지의 등엔트로피 팽창 상태로 평가
    if ~isfinite(X2) || X2 >= 1
        alpha2 = 1; % 하류 전량 증기 -> 단상(SPC) 지배 (증기 배출의 일반적 경우)
    elseif X2 <= 0
        alpha2 = 0; % 하류 전량 액체 (완전 응축) -> HEM 지배
    elseif rho2_l > 0 && rho2_v > 0 && isfinite(rho2_l) && isfinite(rho2_v)
        S_slip = (rho2_l / rho2_v)^(1/3);
        alpha2 = 1 / (1 + ((1 - X2) / X2) * S_slip * (rho2_v / rho2_l));
    else
        warning('Inj_NHNE_VapFeed:InvalidSatDensity', 'Invalid downstream saturation densities (rho2_l=%.2f, rho2_v=%.2f). Defaulting to SPC-dominant flow (alpha2=1).', rho2_l, rho2_v);
        alpha2 = 1; % 증기 배출 시 alpha2~1이 물리적 기본값 (논문 실험 결과)
    end

    % --- HEM 질량 유량 (식 (16)) + 초크 캡 (논문 4.3절 방식) ---
    [r_choke_HEM, choke_state] = FindHEMChokeRatioVap(fluid, P1, s1, h1, T1, rho1);
    if isfinite(r_choke_HEM) && pressure_ratio < r_choke_HEM && choke_state.valid
        hem_choked = true;
        rho2_HEM = choke_state.rho; % 초크점 상태로 캡
        h2_HEM = choke_state.h;
    else
        rho2_HEM = rho2; % 비초크: 실제 하류(P2) 상태 (InjState 결과)
        h2_HEM = h2;
        if ~isfinite(r_choke_HEM)
            warning('Inj_NHNE_VapFeed:HEMChokeSearchFail', 'HEM choke-point search failed. Using downstream (P2) state without cap.');
        end
    end
    if h1 >= h2_HEM
        mdot_HEM = Cd_inj * A_inj * rho2_HEM * sqrt(2 * (h1 - h2_HEM));
    else
        warning('Inj_NHNE_VapFeed:NegativeEnthalpyDrop', 'h1 (%.2f J/kg) < h2 (%.2f J/kg) for HEM calculation. Setting mdot_HEM = 0.', h1, h2_HEM);
        mdot_HEM = 0;
    end

    % --- FML 질량 유량 (식 (23), 증기상 유출) ---
    mdot_inj = alpha2 * mdot_SPC + (1 - alpha2) * mdot_HEM;

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
| HEM 초크점 압력비           | $r_{choke}$               | x.inj.ratio_Pcr_HEM | HEM 플럭스 최대점 (수치 탐색)                |
| 압력비                   | $P_2/P_1$                 | x.inj.ratio_P       |                                   |
| HEM 초크 캡 작동 여부        | —                         | x.inj.choked        | true: 배압이 HEM 초크점 아래 → 캡 적용        |
| Zivi 슬립비              | $S$                       | x.inj.S_slip        | $(\rho_{2,l}/\rho_{2,v})^{1/3}$   |
| 하류 보이드율               | $\alpha_2$                | x.inj.alpha2        | FML 가중치 (식 (24), P₂ 상태 기준)         |
| SPC 질량 유량 (Cd·A 포함)   | $\dot{m}_{\text{SPC}}$    | x.inj.mdot_SPC      |                                   |
| HEM 질량 유량 (Cd·A 포함)   | $\dot{m}_{\text{HEM}}$    | x.inj.mdot_HEM      | 초크점에서 캡 적용                         |
| FML 질량 유량             | $\dot{m}_{\text{inj}}$    | x.inj.mdot          | 식 (23) 가중 결과                      |

```matlab
x.inj.n_isen = n_isen;
x.inj.ratio_Pcr = critical_pressure_ratio; % SPC 임계 압력비 (식 (11))
x.inj.ratio_Pcr_HEM = r_choke_HEM;         % HEM 초크점 압력비 (수치 탐색)
x.inj.ratio_P = pressure_ratio;
x.inj.choked = hem_choked;                 % HEM 캡 작동 여부
x.inj.S_slip = S_slip;
x.inj.alpha2 = alpha2;
% Output the component mass flow rates *including* Cd*A
x.inj.mdot_SPC = mdot_SPC;
x.inj.mdot_HEM = mdot_HEM;
% Output the total calculated mass flow rate
x.inj.mdot = mdot_inj;
```

# 전체 코드
전체 구현은 [Inj_NHNE_VapFeed.m](Inj_NHNE_VapFeed.m) 참조. 위 Input/System/Output 코드에 더해 두 개의 로컬 함수를 포함합니다:

- `FindHEMChokeRatioVap(fluid, P1, s1, h1, guessT, guessRho)` — HEM 질량 플럭스 최대점(초크점) 압력비를 황금분할 탐색으로 찾고, 상류 상태 $(P_1, s_1)$가 직전 호출 대비 허용 오차(인하우스 0.5%, CoolProp 0.1%) 이내면 캐시(persistent)를 재사용. 유효한 결과만 캐시에 저장.
- `SolveIsentropicStateVap(fluid, P_target, s_target, guessT, guessRho)` — 목표 압력까지의 등엔트로피 상태 계산. CoolProp 물성 모델이면 내장 P–s 플래시(`GetPropsPS`)를 사용하고(가짜 근 원천 차단), 인하우스면 lsqnonlin 역산(`InjState_VapFeed`와 동일하게 GetProps 상 플래그 2 사용)에 잔차 무차원화 + 해 검증(잔차/경계 밀착 감지)을 적용 — 기존 탱크 소진 직전 mdot_HEM 폭주(밀도 상한 가짜 근)를 걸러냄.
