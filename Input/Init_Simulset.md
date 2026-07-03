---
tags:
  - 시뮬레이션
  - 설정
  - 초기화
---
# 소개
- `Init_Simulset` 함수는 시뮬레이션의 주요 설정을 초기화합니다.
- 현재 버전에서는 **시험 모드(test mode)** 만을 설정합니다.
- 시험 모드는 시뮬레이션이 연소 시험을 모사할지, 분무 시험을 모사할지를 결정합니다.

# Input

| 명칭     | 기호 | 입력 변수    | 옵션        | 비고                      |
| ------ | -- | -------- | --------- | ----------------------- |
| 시험 모드 | -  | u.test.mode | 1, 2      | 1: 연소 시험, 2: 분무 시험   |

# System
- 입력된 `u.test.mode` 값을 확인합니다.
- 값이 1 또는 2이면 해당 값을 로컬 구조체 `x_simulset.test.mode`에 할당합니다.
- 허용되지 않는 값이 입력되면 에러 메시지를 출력하고 실행을 중지합니다.

# Output

| 명칭     | 기호 | 출력 변수             | 값    | 비고                 |
| ------ | -- | ------------------- | --- | ------------------ |
| 시험 모드 | -  | x_simulset.test.mode | 1 또는 2 | 설정된 시험 모드 값      |

# 전체 코드
```MATLAB
function [x_simulset] = Init_Simulset(u, unit) % unit은 사용되지 않지만 통일성을 위해 유지
%% 입력값 확인
x_simulset = struct(); % 로컬 구조체 초기화

local_mode = -1; % 로컬 변수 초기화
switch u.test.mode
    case 1 % 연소 시험
        local_mode = 1;
    case 2 % 분무 시험
        local_mode = 2;
    otherwise
        error("허용된 시험 모드(u.test.mode)는 1(연소 시험) 또는 2(분무 시험)입니다.");
end

%% 상태량 초기화
x_simulset.test.mode = local_mode;

end
```
