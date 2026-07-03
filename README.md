# StaRbuSt — N₂O 하이브리드 로켓 시뮬레이션 (MATLAB)

아산화질소(N₂O) 산화제 기반 하이브리드 로켓의 연소·추진 성능을 시뮬레이션하는 MATLAB 코드베이스입니다.
탱크 배출(자가가압) → 인젝터 → 그레인 연소 → 연소실 → 노즐로 이어지는 전체 계통을 시간 적분으로 계산하고,
비행 시뮬레이션(Flight_simul)과 지상연소시험(TMS) 데이터 분석 도구를 포함합니다.

## 실행 방법

MATLAB에서 **이 폴더를 현재 폴더(cwd)로 연 상태에서** 실행합니다 (코드가 `addpath(genpath('Input'))` 등 상대 경로를 사용).

```matlab
Test_StaRbuSt   % 실행 후 Config/ 안의 설정 파일 이름을 확장자 없이 입력 (예: 2025_SRS_Hybrid_Oneshot_Cd38_final)
```

- 새 입력 조건을 저장하려면 [Config/Save_Input_Config.m](Config/Save_Input_Config.m)에서 값을 수정 후 실행 → `Config/*.mat` 생성
- 연소 불안정성 주파수 해석: [Test_Frequency.m](Test_Frequency.m)
- 비행 시뮬레이션: [Flight_simul/flight_simul_main.m](Flight_simul/flight_simul_main.m)

## 폴더 구조

| 폴더 | 내용 |
|---|---|
| `Components/` | 구성품별 물리 모델 (1. Tank, 2. Vent-port, 3. Valve, 4. Pipe, 5. Injector, 6. Grain, 7. Combustor, 8. Nozzle) |
| `System/` | 계통 통합 시뮬레이션 루프 (`System.m` 사용 중, `System_new.m`은 개발 중이던 버전) |
| `Input/` | 초기 조건 설정 함수 (`Init_*.m`, `Input.m`) |
| `Config/` | 시험/시뮬레이션별 입력 설정 스냅샷 (`.mat`) 및 `Save_Input_Config.m` |
| `Props/` | N₂O 물성 (Helmholtz EOS 기반 상태방정식) |
| `Output/` | 결과 플롯/저장 함수 (`PlotResults.m` + 구성품별 `Plot_*` / `Gen_*`) |
| `Mat_Data/` | 시뮬레이션 결과 저장 (`.mat`) |
| `Flight_simul/` | 6-DOF 비행 시뮬레이션 및 추력 데이터 |
| `TMS_Data/` | TMS(지상연소시험) 데이터 분석 스크립트 및 가공 결과 (원시 데이터는 아래 참고) |
| `docs/` | 순서도(Mermaid/Obsidian canvas), 수식 정리, 구버전 폴더 구조 문서 |

대부분의 `.m` 파일에는 같은 이름의 `.md` 문서가 짝으로 존재합니다 (모델 설명·수식).

## 버전 정리 내역 (2026-07-03)

`old_ver/`의 세 폴더를 비교해 정리했습니다:

| 폴더 | 마지막 작업 | 판정 |
|---|---|---|
| `StaRbuSt-Simulatrion(MATLAB)` | 2025-09 | **최신 — 이 폴더를 기준으로 채택** |
| `StaRbuSt-Simulatrion(MATLAB)_001` | 2025-05 | 구 스냅샷 (2026-05 수정은 시험 파라미터 값 변경뿐) |
| `MATLAB_oldver_hojin 복사본` | 2025-05 | `_001`과 거의 동일 + Simulink 캐시 |

채택 근거: 기준 폴더에만 Valve/Pipe 컴포넌트, 연소 불안정성 주파수 모델(`Comb_Frequency_*`), Sub-injector 입력,
`Pinj` 폴백 처리 등 후속 개선이 존재하고, 2025년 7~9월 폴라리스 시험 대응 작업이 이어져 있음.

`_001`에서만 있던 파일은 다음 위치로 회수:
- `docs/Flowchart_StaRbuSt.canvas` (Obsidian 순서도)
- `Output/8. Nozzle/Plot_Nozzle_{Gamma,Mw,Rho_c}_t.m` (현재 `PlotResults`에서는 호출되지 않는 독립 플롯 함수)

### 제외된 것

- **TMS 원시 계측 데이터 (~920MB)**: `.lvm` 원본과 대용량 캐시(`TMS_Data_cache.mat`, `Cold_Flow_Data_cache.mat`), 가공 `.mat`(`TMS_Data/TMS_Data/`)은
  `old_ver/StaRbuSt-Simulatrion(MATLAB)/TMS_Data/`에 그대로 있습니다. TMS 분석 스크립트 실행 시 해당 경로의 데이터가 필요합니다.
- `.DS_Store`, Simulink 캐시(`GSE_simulator.slxc`, `slprj/` — 원본 `.slx` 모델 없음)

루트의 `2025_SRS_Hybrid_Oneshot_Cd4*.mat`, `..._Cd38.mat` 4개는 `Config/`의 동명 파일과 내용이 다른 후기 스냅샷이라 원위치(루트)에 유지했습니다.

## 참고 문서

- [docs/StaRbuSt_flowchart.md](docs/StaRbuSt_flowchart.md) — 전체 계산 흐름도
- [docs/Mermaid_math.md](docs/Mermaid_math.md) — 수식 정리
- [docs/StaRbuSt 폴더 구조.md](docs/StaRbuSt%20폴더%20구조.md) — 구버전(2025-05) 기준 파일 목록 (Valve/Pipe/주파수 모델 반영 전)
- [Test_StaRbuSt.md](Test_StaRbuSt.md) — 메인 스크립트 설명
