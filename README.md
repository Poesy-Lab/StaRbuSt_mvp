# StaRbuSt

아산화질소(N₂O) 자가가압 하이브리드 로켓의 성능을 예측하는 MATLAB 시뮬레이터.
탱크 블로다운에서 공급 라인, 인젝터, 그레인 연소, 노즐까지 한 사이클로 시간 적분한다.
2026년 수류(분무)시험과 연소시험 실측으로 교정을 마쳤고, 6자유도 비행 시뮬레이션과
시험 데이터 비교 도구가 같이 들어 있다.

한국항공대학교 로켓동아리 SRS에서 2025년 연구부 1기 추진팀장 박호진(SRS 33기)이 만들었다.
지상시험 데이터와 시뮬레이션을 오가며 모터를 설계하는 과정을 담은 프로젝트이고,
일본 노시로 로켓대회 출전으로 가는 발판이 됐다.

- [2025 일본 노시로 대회 준비기](https://blog.naver.com/wdh3168/223986008141)
- [KAU SRS 유튜브](https://www.youtube.com/@KAU_SRS_Rocket/videos)

## 준비물

- MATLAB. R2026a에서 개발했다. `lsqnonlin`을 쓰는 경로가 있어서 Optimization Toolbox가 필요하다.
- 파이썬 패키지 두 개. 연소 해석(CEA)과 N₂O 물성이 파이썬으로 돌아간다.

```bash
pip install -r requirements.txt
```

MATLAB에서 어느 파이썬을 쓸지 한 번 지정해 준다. MATLAB을 켠 직후, 파이썬을 아직 안 부른 상태에서만 바꿀 수 있다.

```matlab
pyenv('Version', '/opt/homebrew/anaconda3/bin/python3')   % 본인 경로로
```

무엇이 언제 필요한지는 아래와 같다. 없으면 해당 기능만 빠지고 나머지는 돌아간다.

| 하려는 일 | 필요한 패키지 |
|---|---|
| 연소 시뮬레이션 | rocketcea |
| CoolProp 물성 (`u.tank.prop_model = "CoolProp"`) | CoolProp |
| 공급 라인 모델 (`u.feed.mode = 1`) | CoolProp |
| 분무 모드 + 인하우스 EOS | 없음 |

## 실행

MATLAB에서 이 폴더를 현재 폴더로 열고 시작한다. 코드가 상대 경로로 `addpath`를 하기 때문이다.

대화형 실행:

```matlab
Test_StaRbuSt
```

설정 이름을 물어보면 `Config/` 안의 mat 파일 이름을 확장자 없이 입력한다. 하위 폴더까지 알아서 찾는다.
끝나면 플롯 창이 뜨고 결과는 `Mat_Data/<설정이름>/`에 저장된다.

스크립트 실행(플롯 없음, 스윕용):

```matlab
[y, x] = Run_Config('2026_nova_line_hot');   % 전체 시간 이력 y까지 저장
```

들어 있는 대표 설정:

| 설정 | 내용 |
|---|---|
| `2026_nova_line_hot` | 2026-07-03 연소시험 재현. 교정 기준 케이스 |
| `2026_nova_line_cold` | 2026 N₂O 분무시험 재현 (공급 라인 + 2상 인젝터) |
| `2026_nova_redesign` | 고도 250 m 제한 재설계안 (탱크 112 mm, 상세는 docs/재설계) |

시험 데이터와 겹쳐 보기:

```matlab
addpath('TMS_Data')
Compare_2026_Spray()      % 분무시험 vs 시뮬
Compare_2026_HotFire()    % 연소시험 vs 시뮬
```

원시 계측 파일(lvm)은 저장소에 없어서 클론만 받아서는 이 두 개를 다시 그릴 수 없다.
결과 그림은 `TMS_Data/Compare_2026_*.png`로 들어 있다.

비행 시뮬레이션:

```matlab
addpath('Flight_simul')
Flight_From_Config('2026_nova_redesign')     % 고도, 레일 탈출속도 요약 출력
```

궤적 애니메이션까지 보려면 `Flight_simul/flight_simul_main.m`을 직접 연다.

## 새 조건 만들기

`Config/Save_Input_Config.m`에서 값을 고치고 실행하면 `Config/`에 mat 파일이 저장된다.
자주 만지게 되는 스위치는 셋이다.

- `u.inj.model_LiqFeed` : 인젝터 유량 모델. NHNE, CdA, FML, HEMc 중 문자열 키워드로 고른다.
  공급 라인을 켤 거라면 HEMc를 써야 한다.
- `u.tank.prop_model` : 산화제 물성. 기본은 인하우스 Helmholtz EOS(Lemmon–Span 2006)이고,
  "CoolProp"을 지정하면 같은 상관식을 CoolProp 플래시로 계산한다. 공급 라인 모델은 CoolProp 전용.
- `u.feed.mode` : 0이면 탱크와 인젝터 직결, 1이면 공급 라인 모델.
  플렉시블 호스와 볼밸브의 2상 압력손실을 계산한다. 2026 수류시험으로 검증했다.

연소 불안정 주파수 해석은 `Test_Frequency.m`에 따로 있다.

## 폴더 구조

| 폴더 | 내용 |
|---|---|
| `Components/` | 구성품별 물리 모델. Tank, Vent-port, Valve, Pipe, Injector, Grain, Combustor, Nozzle |
| `System/` | 시뮬레이션 메인 루프 (`System.m`) |
| `Input/` | 초기 조건과 단위 변환 (`Init_*.m`, `Input.m`) |
| `Config/` | 입력 설정. 연도별 하위 폴더로 구분 |
| `Props/` | N₂O 물성. 인하우스 EOS와 CoolProp 브리지 |
| `Output/` | 결과 플롯과 mat 저장 |
| `Mat_Data/` | 시뮬레이션 결과. 설정별 하위 폴더 |
| `Flight_simul/` | 6자유도 비행 시뮬레이션 |
| `TMS_Data/` | 지상시험 데이터 분석과 시험-시뮬 비교 도구 |
| `docs/` | 흐름도, 수식 정리, 논문 요약 노트, 2026 시험 문서, 재설계 보고 |

거의 모든 `.m` 파일 옆에 같은 이름의 `.md`가 있다. 모델의 출처와 수식을 거기에 적어 뒀다.

원시 계측 데이터(lvm, xlsx)와 논문 PDF 원문은 용량 때문에 올리지 않았다. 필요하면 연락 바람.
시험 조건 문서와 처리 스크립트, 결과 그림은 `docs/시험 정보/`에 있다.

## 더 읽을 것

- [docs/StaRbuSt_flowchart.md](docs/StaRbuSt_flowchart.md) — 전체 계산 흐름도
- [docs/Mermaid_math.md](docs/Mermaid_math.md) — 수식 정리
- [docs/재설계/재설계 결과.md](docs/재설계/재설계%20결과.md) — 2026 재설계 근거와 결론
- [Test_StaRbuSt.md](Test_StaRbuSt.md) — 메인 스크립트 설명
