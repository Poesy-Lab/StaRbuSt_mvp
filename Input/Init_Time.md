---
tags:
  - 시간
  - 초기화
---
# 소개
- `Init_Time` 함수는 시뮬레이션의 시간 축 관련 파라미터를 설정하고 초기화합니다.
- 사용자는 시뮬레이션 시작 시간(`start`), 엔진 연소 시간(`run`), 시뮬레이션 종료 시간(`stop`), 그리고 시간 간격(`dt`)을 다양한 시간 단위로 입력할 수 있습니다.
- 함수는 입력된 모든 시간 관련 값들을 표준 단위인 초(s)로 변환합니다.
- 변환된 값을 바탕으로 시뮬레이션 전체 시간 벡터(`t`)와 총 시간 스텝 수(`N`)를 계산하여 저장합니다.

# Input

| 명칭        | 기호       | 입력 변수     | 단위 옵션       | 비고                  |
| --------- | -------- | --------- | ----------- | ------------------- |
| 시작 시간    | $t_{start}$ | u.time.start| s, ms, min, hr | 시뮬레이션 시작 시간        |
| 연소 시간    | $t_{run}$  | u.time.run  | s, ms, min, hr | 엔진 연소 지속 시간        |
| 종료 시간    | $t_{stop}$ | u.time.stop | s, ms, min, hr | 시뮬레이션 종료 시간        |
| 시간 간격    | $dt$     | u.time.dt   | s, ms, min, hr | 시뮬레이션 각 스텝의 시간 간격 |

# System
- 입력된 각 시간 파라미터(`start`, `run`, `stop`, `dt`)의 단위를 확인하고 `switch` 문을 사용하여 초(s) 단위로 변환합니다.
- 변환된 `t_start`, `dt`, `t_stop` 값을 사용하여 MATLAB 콜론 연산자(`:`)로 시뮬레이션 시간 벡터 `x.time.t` (시작부터 종료까지 dt 간격의 시간 배열)를 생성합니다.
- `length` 함수를 사용하여 생성된 시간 벡터 `x.time.t`의 길이를 계산하여 총 시간 스텝 수 `x.time.N`을 구합니다.

# Output

| 명칭        | 기호       | 출력 변수    | 단위 | 비고                         |
| --------- | -------- | -------- | -- | -------------------------- |
| 시작 시간    | $t_{start}$ | x.time.start| s  | 표준 단위로 변환된 시작 시간         |
| 연소 시간    | $t_{run}$  | x.time.run  | s  | 표준 단위로 변환된 연소 시간         |
| 종료 시간    | $t_{stop}$ | x.time.stop | s  | 표준 단위로 변환된 종료 시간         |
| 시간 간격    | $dt$     | x.time.dt   | s  | 표준 단위로 변환된 시간 간격         |
| 시간 벡터    | $t$      | x.time.t    | s  | 시뮬레이션 전체 시간 스텝 벡터       |
| 시간 스텝 수  | $N$      | x.time.N    | -  | 총 시뮬레이션 시간 스텝 개수 (`length(t)`)| 

# 전체 코드
```MATLAB
function [x] = Init_Time(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환 (모든 시간을 초 단위로 변환)

% 시작 시간 (start)
switch unit.time.start
    case "s"
        t_start = u.time.start;
    case "ms"
        t_start = u.time.start * 1e-3;
    case "min"
        t_start = u.time.start * 60;
    case "hr"
        t_start = u.time.start * 3600;
    otherwise
        error("허용된 시작 시간 단위: s, ms, min, hr");
end

% 연소 시간 (run)
switch unit.time.run
    case "s"
        t_run = u.time.run;
    case "ms"
        t_run = u.time.run * 1e-3;
    case "min"
        t_run = u.time.run * 60;
    case "hr"
        t_run = u.time.run * 3600;
    otherwise
        error("허용된 연소 시간 단위: s, ms, min, hr");
end

% 종료 시간 (stop)
switch unit.time.stop
    case "s"
        t_stop = u.time.stop;
    case "ms"
        t_stop = u.time.stop * 1e-3;
    case "min"
        t_stop = u.time.stop * 60;
    case "hr"
        t_stop = u.time.stop * 3600;
    otherwise
        error("허용된 종료 시간 단위: s, ms, min, hr");
end

% 시간 간격 (dt)
switch unit.time.dt
    case "s"
        dt = u.time.dt;
    case "ms"
        dt = u.time.dt * 1e-3;
    case "min"
        dt = u.time.dt * 60;
    case "hr"
        dt = u.time.dt * 3600;
    otherwise
        error("허용된 시간 간격 단위: s, ms, min, hr");
end

%% 상태량 초기화
x.time.start = t_start; % s
x.time.run = t_run;     % s
x.time.stop = t_stop;   % s
x.time.dt = dt;         % s
x.time.t = t_start:dt:t_stop; % 시뮬레이션 시간 벡터 (s)
x.time.N = length(x.time.t); % 시간 스텝 수

end
```
