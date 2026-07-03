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

## 데이터 파일 정리 내역 (2026-07-03, 2차)

- **Config 재구성**: 60여 개 flat `.mat`을 `2025_campaign/`과 `archive_2018-2024/`로 분리. 일회용 테스트 저장본(`cccccxc`, `dddd`, `test 1`, `test2`)과 중복 백업 zip은 삭제 (git 첫 커밋에 보존됨).
- **루트에 흘러나온 `.mat` 4개 삭제**: `Save_Input_Config.m`이 현재 폴더(cwd)에 저장하던 동작 때문에 생긴 구버전 스냅샷 — 내용 비교 결과 모두 `Config/`의 동명 파일이 더 최신. 저장 경로가 항상 `Config/`가 되도록 코드도 수정.
- **Mat_Data 재구성**: 152개 결과 파일을 실행 이름별 하위 폴더(`Mat_Data/<설정이름>/`)로 정리하고, `GenMatResults.m`이 앞으로도 하위 폴더에 저장하도록 수정.
- **깨진 절대 경로 수정**: `Flight_simul/Excel_gen.m`, `flight_simul_main.m`, `TMS_Data/mat2excel.m`의 Windows 절대 경로(`C:\Users\sitra\...`)를 스크립트 위치 기준 상대 경로로 교체.

## 참고 문서

- [docs/StaRbuSt_flowchart.md](docs/StaRbuSt_flowchart.md) — 전체 계산 흐름도
- [docs/Mermaid_math.md](docs/Mermaid_math.md) — 수식 정리
- [docs/StaRbuSt 폴더 구조.md](docs/StaRbuSt%20폴더%20구조.md) — 구버전(2025-05) 기준 파일 목록 (Valve/Pipe/주파수 모델 반영 전)
- [Test_StaRbuSt.md](Test_StaRbuSt.md) — 메인 스크립트 설명
