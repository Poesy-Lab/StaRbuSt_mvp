---
tags:
  - 공급라인
  - 2상유동
  - 압력손실
Author: SRS 33기 박호진
---
# 소개
- `Feed_Line.m`은 **탱크 출구에서 인젝터 전방까지의 공급 라인 압력손실**을 계산하는 함수입니다. 경로: 탱크 출구(입구손실) → 플렉시블 파이프(ㄴ자 벤드 포함) → 파이프1 → 볼밸브 → 파이프2(인젝터 전방, 압력 계측점).
- 자가가압 N₂O는 포화 상태로 라인에 진입하므로 압력이 떨어지는 즉시 **플래싱**이 일어나 라인 전체가 2상 유동이 됩니다. 모델 근거:
	- **균질류 + Dukler 2상 점도 + Nikuradse 마찰**: Tada et al. (2024, Trans. JSASS)가 자가가압 N₂O/CO₂ 라인(1/2", 200~550 g/s, 기포류)에서 MAE 12~15%로 실증한 조합. 고속카메라 가시화로 이 영역의 유동이 마이크로버블 균질 기포류임을 확인.
	- **볼밸브 2상 무회복 처리**: 단상 Cv는 하류 압력회복을 포함한 값이나, 플래싱 유동에서는 스로트 감압 시 기화로 회복이 사라져 축소 보어가 오리피스처럼 동작 → 보어 기준 무회복 K로 환산 (`Init_Feed.m`).
	- **가속 압손**: 플래싱으로 비체적이 커지며 유체가 가속 (균질 운동량식).
- 라인은 단열로 가정 → **비엔탈피 보존** (마찰 소산은 내부에너지로 회귀). 상태는 (P, h) 플래시로 추적.
- **검증**: 2026 수류시험 2회 — 실측 mdot·P_tank 입력 시 P_inj 예측 교차 RMSE ~2.5 bar (전체 낙차 12~14 bar 대비).
- **요구 사항**: CoolProp 물성 모델(`GetPropsPH`). 인하우스 EOS 선택 시 에러 발생.
- **액상/증기상 모두 지원** (v2): 세 번째 인자 `phase`('liq' 기본 / 'vap')로 라인 입구 엔탈피를 탱크 액상(h_l) 또는 증기상(h_v)으로 선택. 증기상은 등엔탈피 스로틀링으로 출구가 약과열 증기가 될 수 있으나, 지렛대 클램프(X ≤ 1)로 포화증기 물성으로 근사합니다 (밀도 오차 수 % 이내; 증기 유동은 속도가 커서 라인 압손이 수 bar~10 bar 이상으로 지배적).
- 호출 방식: `Inj_HEMc_LiqFeed.m`(액상) / `Inj_NHNE_VapFeed.m`(증기상)의 유량 결합 루프에서 가정 유량으로 반복 호출됨 (상태 구조체 `x`를 변경하지 않고 결과 구조체 `out`만 반환).

# Input

| 명칭            | 기호               | 입력 변수          | 비고                          |
| ------------- | ---------------- | -------------- | --------------------------- |
| 시뮬 상태        | —                | x              | 탱크 상태(P, h)와 x.feed 설정 사용  |
| 가정 질량 유량     | $\dot m$          | mdot [kg/s]    | 결합 루프의 반복 변수                |
| 유출 상          | —                | phase          | 'liq'(기본) / 'vap'            |
| 탱크 압력        | $P_0$            | x.tank.P       | 라인 입구 압력                    |
| 라인 입구 엔탈피    | $h_1$            | x.tank.h_l 또는 h_v | 라인 전체에서 보존 (phase에 따름)  |
| 입구손실 계수      | $K_{ent}$        | x.feed.K_ent   | 기본 0.5                      |
| 플렉시블 내경/길이/마찰배수/벤드 | — | x.feed.flex.D/L/fmult/K_bend | 주름관이면 fmult 4~10 |
| 직관 내경/길이     | —                | x.feed.pipe.D/L1/L2 | 3/8" OD 튜브               |
| 밸브 무회복 K     | $K_{valve}$      | x.feed.valve.K | `Init_Feed`에서 보어·Cd로 환산     |

# System
- 각 구간에서 국소 (P, h) 플래시로 균질 물성을 얻고 압력을 행진시킵니다:
$$
\rho_{TP} = \left( \frac{x}{\rho_v} + \frac{1-x}{\rho_l} \right)^{-1}, \qquad
\mu_{TP} = \alpha \mu_v + (1-\alpha)\mu_l \;\;(\text{Dukler}), \qquad
\alpha = \frac{x/\rho_v}{x/\rho_v + (1-x)/\rho_l}
$$
- 직관 마찰 (Nikuradse, Tada 2024 사용식) + 가속 압손:
$$
\Delta P_f = f_{mult} \cdot \lambda(Re_{TP}) \frac{\Delta L}{D} \frac{G^2}{2\rho_{TP}}, \qquad
\lambda = 0.0032 + 0.221\,Re_{TP}^{-0.237}, \qquad
\Delta P_{acc} = G^2 \left( \frac{1}{\rho_{out}} - \frac{1}{\rho_{in}} \right)
$$
- 집중손실 요소 (입구, 벤드, 밸브):
$$
\Delta P_K = K \frac{G^2}{2\rho_{TP}} \;(+\, \Delta P_{acc})
$$
- 밸브 무회복 K (Init_Feed에서 환산; $A_{line}$은 직관 단면적, $A_{bore}$는 밸브 보어):
$$
K_{valve} = \left( \frac{A_{line}}{C_{d,bore} A_{bore}} \right)^2 - 1
$$
- 어느 지점에서든 압력이 하한(1.15 bar)에 닿으면 "해당 유량 통과 불가"로 판정하고 `ok = false`를 반환합니다 (결합 루프에서 유량 상한으로 해석).

# Output

| 명칭          | 출력 변수        | 비고                              |
| ----------- | ------------ | ------------------------------- |
| 계산 성공 여부    | out.ok       | false: 해당 유량이 라인 통과 불가          |
| 라인 출구 압력    | out.P_out    | 인젝터 전방 압력 [Pa] (파이프2 끝)         |
| 라인 출구 엔탈피   | out.h_out    | = 라인 입구 엔탈피 (보존)            |
| 라인 출구 건도    | out.x_out    | 라인 플래싱 결과 (인젝터 입구 건도)           |
| 라인 출구 혼합 밀도 | out.rho_out  | [kg/m^3]                        |
| 라인 총 압력손실   | out.dP_line  | P_tank − P_out [Pa]             |

기록: 수렴된 값이 `Inj_HEMc_LiqFeed`(액상) / `Inj_NHNE_VapFeed`(증기상)에 의해 `x.feed.P_out / x_out / dP_line`으로 저장되어 `y.feed.*`에 로깅됩니다.

# 전체 코드
전체 구현은 [Feed_Line.m](Feed_Line.m) 참조. 내부 구성:
- `tp_props(fluid, P, h)` — (P,h) 플래시 + Dukler 2상 점도 ([N2O_Viscosity.m](../../Props/N2O_Viscosity.m), ESDU 91022)
- `pipe_march(...)` — 직관 0.05 m 간격 행진 (마찰 + 가속 1회 보정)
- `k_element(...)` — 집중손실 요소 (+가속 보정)
