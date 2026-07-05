---
tags:
  - 물성
  - CoolProp
  - EOS
Author: SRS 33기 박호진
---
# 소개
- `N2O_CoolProp.m`은 **CoolProp 기반 N₂O 물성 모델**로, 인하우스 `N2O`(+`HelmholtzEOS`) 클래스와 동일한 인터페이스를 제공하는 대체 구현입니다.
- 선택 방법: `Save_Input_Config.m`에서
  ```matlab
  u.tank.prop_model = "CoolProp"; % 또는 "HelmholtzEOS(in-house)" (기본)
  ```
  `Init_Tank.m`이 이 문자열로 `N2O()` 또는 `N2O_CoolProp()`을 인스턴스화하며, 이후 모든 컴포넌트(Tank, Vent, InjState, FML 인젝터 등)는 `x.fluid` 다형성으로 자동 반영됩니다. 구버전 설정 파일(필드 없음)은 인하우스로 동작합니다.
- **정확도는 동일**: CoolProp의 N₂O도 인하우스와 같은 Lemmon–Span (2006) 상관식입니다. 차이는 **플래시 견고성**입니다.

# 인터페이스

| 메서드 | 용도 | 비고 |
|---|---|---|
| `GetProps(T, rho, 상플래그)` | 기존 FluidEOS와 동일 (0 액체 / 1 포화 / 2 기체 / 생략 자동) | 출력 구조체 필드 동일 |
| `satDensity(T)` | 포화 액/증기 밀도 | CoolProp 포화 계산 |
| `GetPropsPS(P, s)` | **P–s 직접 플래시** (등엔트로피 상태) | `InjState_*`, FML/HEMc 초크점 탐색이 사용 |
| `GetPropsDH(rho, h)` | **ρ–h 직접 플래시** (탱크 엔탈피 알고리즘) | `Tank_{Pre,Liq,Vap}Feed`가 사용 |
| `GetPropsPH(P, h)` | **P–h 직접 플래시** (단열 라인에서 h 보존) | `Feed_Line`(공급 라인 행진)이 사용 |
| `CEACard` | CEA 등록 카드 (N2O.m과 동일) | |

- 상태 솔버들은 `ismethod(fluid, 'GetPropsPS')` / `'GetPropsDH'`로 직접 플래시 지원 여부를 감지해 **lsqnonlin 역산을 건너뜁니다**. 인하우스 모델 선택 시에는 기존 lsqnonlin 경로가 그대로 사용됩니다 (과거 결과 재현성 유지).
- 직접 플래시의 효과: 돔 내부 가짜 근(탱크 소진 직전 `mdot_HEM` 폭주의 원인) 원천 차단, 초크점 탐색 비용 감소(캐시 허용 오차 0.5%→0.1%로 조밀화되어 유량 곡선 계단 완화), 속도 향상.

# 주의 사항
- **파이썬 의존**: MATLAB `pyenv`에 CoolProp이 설치된 파이썬이 연결되어 있어야 합니다 (CEA와 동일 경로: `pyenv('Version', '/opt/homebrew/anaconda3/bin/python3')`). CoolProp 선택 시 분무 시험 모드도 파이썬이 필요해집니다.
- **h/s 기준상태**: CoolProp과 인하우스 EOS는 h/s의 영점이 다릅니다. 한 런 안에서는 일관되므로 P, T, ρ, 유량, 추력은 모델 간 직접 비교 가능하지만, **h/s 절대값 플롯은 모델 간 상수 오프셋**이 있습니다. 비교가 필요하면 차이량(Δh 등)으로 비교하세요.
- **실패 처리**: 플래시 실패(영역 밖 등) 시 예외를 던지지 않고 `state = -1`(전 필드 NaN)을 반환합니다. 호출측은 `state == -1` 검사 후 폴백(lsqnonlin)하거나 무효 처리합니다.
- 검증: [Compare_EOS_CoolProp.m](Compare_EOS_CoolProp.m)으로 두 모델의 포화 물성·음속·잠열을 대조할 수 있습니다 (상대오차 ~0.1% 수준이 정상).

# 전체 코드
전체 구현은 [N2O_CoolProp.m](N2O_CoolProp.m) 참조. 내부 구성:
- `cpsi(...)` — `py.CoolProp.CoolProp.PropsSI` 단일 호출 래퍼
- `queryState(...)` — 지정 입력쌍의 단상 물성 일괄 조회 (P, T, ρ, u, s, h, cp, cv, c)
- `mixtureProps(T, X)` — 포화 혼합 구성 (건도 가중 + Wood 음속, `FluidEOS`의 포화 분기와 동일 규약)
- `singleProps(st, is_liquid)` — 단상 구성 (해당 상 필드에 값, 반대 상 필드 0 — 인하우스 규약 동일)
