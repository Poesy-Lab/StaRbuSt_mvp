---
tags:
  - 대기
  - 초기화
---
# 소개
- `Init_Amb` 함수는 주변 환경 조건을 초기화합니다.
- 압력(P), 온도(T), 중력가속도(g)를 포함한 대기 환경 변수를 사용자가 지정한 단위로 입력받아 계산에 사용될 표준 단위(SI)로 변환합니다.

# Input

| 명칭      | 기호  | 입력 변수    | 단위 옵션                    | 비고       |
| --------- | --- | -------- | -------------------------- | -------- |
| 대기 압력   | $P_{amb}$ | u.amb.P  | Pa, hPa, MPa, bar, psi, atm, mmHg | 주변 대기 압력 |
| 대기 온도   | $T_{amb}$ | u.amb.T  | K, °C, °F, C, F            | 주변 대기 온도 |
| 중력 가속도 | $g$   | u.amb.g  | m/s², cm/s², ft/s²         | 중력 가속도   |

# System
- 입력된 각 물리량(`P`, `T`, `g`)의 단위를 확인하고 `switch` 문을 사용하여 표준 단위(Pa, K, m/s²)로 변환합니다.
- 허용되지 않는 단위가 입력되면 에러 메시지를 출력하고 실행을 중지합니다.

# Output

| 명칭      | 기호  | 출력 변수  | 단위  | 비고        |
| --------- | --- | ------ | --- | --------- |
| 대기 압력   | $P_{amb}$ | x.amb.P | Pa  | 표준 단위로 변환된 값 |
| 대기 온도   | $T_{amb}$ | x.amb.T | K   | 표준 단위로 변환된 값 |
| 중력 가속도 | $g$   | x.amb.g | m/s² | 표준 단위로 변환된 값 |

# 전체 코드
```MATLAB
function [x] = Init_Amb(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환
% amb.P, Pa
switch unit.amb.P
	case "Pa"
		P = u.amb.P;
	case "hPa"
		P = u.amb.P * 100;
	case "MPa"
		P = u.amb.P * 1e6;
	case "bar"
		P = u.amb.P * 1e5;
	case "psi"
		P = u.amb.P * 6894.757;
	case "atm"
		P = u.amb.P * 101325;
	case "mmHg"
		P = u.amb.P * 133.322;
	otherwise
		error("Pa, hPa, MPa, bar, psi, atm, mmHg 단위만 입력 가능");
end

% amb.T, K
switch unit.amb.T
	case "K"
		T = u.amb.T;
	case "°C"
		T = u.amb.T + 273.15;
	case "°F"
		T = (u.amb.T - 32) * 5/9 +273.15;
	case "C"
		T = u.amb.T + 273.15;
	case "F"
		T = (u.amb.T - 32) * 5/9 + 273.15;
	otherwise
		error("K, °C, °F, C, F 단위만 입력 가능")
end

% amb.g, m/s^2
switch unit.amb.g
	case "m/s^2"
		g = u.amb.g;
	case "cm/s^2"
		g = u.amb.g * 0.01;
	case "ft/s^2"
		g = u.amb.g * 0.3048;
	otherwise
		error("허용된 단위: m/s^2, cm/s^2, ft/s^2만 입력 가능");
end

%% 상태량 초기화
x.amb.P = P; % Pa
x.amb.T = T; % K
x.amb.g = g; % m/s^2

end