# StaRbuSt — N₂O 하이브리드 로켓 시뮬레이션 (MATLAB)

아산화질소(N₂O) 산화제 기반 하이브리드 로켓의 연소·추진 성능을 시뮬레이션하는 MATLAB 코드베이스입니다.
탱크 배출(자가가압) → 인젝터 → 그레인 연소 → 연소실 → 노즐로 이어지는 전체 계통을 시간 적분으로 계산하고,
비행 시뮬레이션(Flight_simul)과 지상연소시험(TMS) 데이터 분석 도구를 포함합니다.

## 실행 방법

MATLAB에서 **이 폴더를 현재 폴더(cwd)로 연 상태에서** 실행합니다 (코드가 `addpath(genpath('Input'))` 등 상대 경로를 사용).

```matlab
Test_StaRbuSt   % 실행 후 Config/ 안의 설정 파일 이름을 확장자 없이 입력 (예: 2025_SRS_Hybrid_Oneshot_Cd38_final)
```

- 설정 파일은 `Config/` 하위 폴더까지 재귀 검색되므로 폴더 구분 없이 파일 이름만 입력하면 됩니다.
- 시뮬레이션 결과는 `Mat_Data/<설정이름>/` 하위 폴더에 자동 저장됩니다.
- 새 입력 조건을 저장하려면 [Config/Save_Input_Config.m](Config/Save_Input_Config.m)에서 값을 수정 후 실행 → 실행 위치와 무관하게 `Config/`에 저장됩니다.
- **모델 선택** (설정 파일에서 문자열로 지정):
  - 인젝터 질량유량: `u.inj.model_LiqFeed` — NHNE(Dyer), CdA, **FML**(보이드율 가중, La Luna et al. 2022 + 2상 초크점 수치 탐색) / `u.inj.model_VapFeed` — ICF, CdA, NHNE(FML 증기상)
  - 산화제 물성: `u.tank.prop_model` — 인하우스 Helmholtz EOS(Lemmon–Span 2006, 기본) 또는 **CoolProp**(동일 상관식, 내장 P–s/ρ–h 플래시로 상태 계산이 견고·고속, MATLAB pyenv 필요)
  - 급기 라인: `u.feed.mode` — 탱크-인젝터 직결(0) 또는 **2상 균질류 라인 모델**(1: 플렉시블·볼밸브 압손 + 라인 플래싱, Tada 2024 검증 조합; 인젝터 모델 `HEMc`(2상 입구 HEM+초크 캡)와 결합, 2026 수류시험으로 검증)
- 연소 불안정성 주파수 해석: [Test_Frequency.m](Test_Frequency.m)
- 비행 시뮬레이션: [Flight_simul/flight_simul_main.m](Flight_simul/flight_simul_main.m)

## 폴더 구조

| 폴더 | 내용 |
|---|---|
| `Components/` | 구성품별 물리 모델 (1. Tank, 2. Vent-port, 3. Valve, 4. Pipe, 5. Injector, 6. Grain, 7. Combustor, 8. Nozzle) |
| `System/` | 계통 통합 시뮬레이션 루프 (`System.m` 사용 중, `System_new.m`은 개발 중이던 버전) |
| `Input/` | 초기 조건 설정 함수 (`Init_*.m`, `Input.m`) |
| `Config/` | 입력 설정 (`Save_Input_Config.m`, `default_config.mat`) — `2025_campaign/`(2025 캠페인 스윕), `archive_2018-2024/`(과거 연도) 하위 폴더로 구분 |
| `Props/` | N₂O 물성 (Helmholtz EOS 기반 상태방정식) |
| `Output/` | 결과 플롯/저장 함수 (`PlotResults.m` + 구성품별 `Plot_*` / `Gen_*`) |
| `Mat_Data/` | 시뮬레이션 결과 (`.mat`) — 실행(설정)별 하위 폴더로 정리, `GenMatResults`가 자동으로 하위 폴더에 저장 |
| `Flight_simul/` | 6-DOF 비행 시뮬레이션 및 추력 데이터 |
| `TMS_Data/` | TMS(지상연소시험) 데이터 분석 스크립트 및 가공 결과 (원시 계측 데이터는 용량 문제로 저장소에 미포함) |
| `docs/` | 순서도(Mermaid/Obsidian canvas), 수식 정리, 논문 요약 노트(`paper/`), 2026 시험 조건·처리 문서(`시험 정보/`), 재설계 보고(`재설계/`) |

용량 관계로 원시·가공 계측 데이터(LVM/xlsx)와 논문 PDF 원문은 저장소에 포함하지 않습니다 (로컬 보관, 요청 시 제공). 시험 조건 문서·처리 스크립트·결과 그림은 포함되어 있습니다.

대부분의 `.m` 파일에는 같은 이름의 `.md` 문서가 짝으로 존재합니다 (모델 설명·수식).

## 참고 문서

- [docs/StaRbuSt_flowchart.md](docs/StaRbuSt_flowchart.md) — 전체 계산 흐름도
- [docs/Mermaid_math.md](docs/Mermaid_math.md) — 수식 정리
- [docs/StaRbuSt 폴더 구조.md](docs/StaRbuSt%20폴더%20구조.md) — 구버전(2025-05) 기준 파일 목록 (Valve/Pipe/주파수 모델 반영 전)
- [Test_StaRbuSt.md](Test_StaRbuSt.md) — 메인 스크립트 설명
