---
tags:
  - 탱크
  - 초기화
---
# 소개
- `Init_Tank` 함수는 시뮬레이션에 사용될 초기 탱크 상태를 설정합니다.
- 사용자는 탱크 부피(직접 또는 형상 정보), 내부 유체의 질량, 온도, 종류를 다양한 단위로 입력할 수 있습니다.
- 함수는 입력된 값들을 표준 단위(m³, kg, K)로 변환하고, 선택된 유체 종류에 따라 해당 유체의 물성치 계산 객체를 생성합니다.
- 최종적으로 변환된 물리량과 유체 물성치 객체를 사용하여 탱크의 초기 열역학적 상태(압력, 밀도, 상 상태, 건도 등)와 각 상(액체, 증기) 및 혼합물의 상세 물성치를 계산하여 초기화합니다.

# Input

| 구분     | 명칭       | 기호 | 입력 변수     | 단위 옵션          | 비고                               |
| -------- | -------- | -- | ----------- | -------------- | -------------------------------- |
| 형상     | 부피       | V  | u.tank.V    | m³, L, cm³, ft³, gal | 탱크 부피 직접 입력 (d, h 입력 시 무시)     |
|          | 직경       | d  | u.tank.d    | m, mm, cm, in    | 원통형 탱크 직경 (V 입력 시 무시)         |
|          | 높이       | h  | u.tank.h    | m, mm, cm, in    | 원통형 탱크 높이 (V 입력 시 무시)         |
| 내용물    | 질량       | m  | u.tank.m    | kg, g, lb, oz   | 탱크 내부 유체 질량                     |
|          | 온도       | T  | u.tank.T    | K, °C, °F, C, F | 탱크 내부 유체 온도                     |
|          | 유체 종류    | -  | u.tank.fluid | N2O, CO2       | 탱크 내부 유체 종류 (해당 유체 클래스 로드) |

# System
- **부피 계산/변환**: `isfield` 함수로 사용자가 부피(`V`)를 직접 입력했는지, 아니면 직경(`d`)과 높이(`h`)를 입력했는지 확인합니다.
    - `V` 입력 시: `switch` 문을 사용하여 입력된 단위를 m³로 변환합니다.
    - `d`, `h` 입력 시: 각 치수의 단위를 m으로 변환한 후, 원통 부피 공식 ($V = \pi (d/2)^2 h$)을 사용하여 m³ 단위의 부피를 계산합니다.
    - 부피 정보가 없으면 에러를 발생시킵니다.
- **질량 변환**: `switch` 문을 사용하여 입력된 질량 단위(`unit.tank.m`)를 kg으로 변환합니다.
- **온도 변환**: `switch` 문을 사용하여 입력된 온도 단위(`unit.tank.T`)를 K으로 변환합니다.
- **유체 객체 생성**: `switch` 문을 사용하여 `u.tank.fluid` 값에 따라 `N2O()` 또는 `CO2()` 클래스 생성자를 호출하여 유체 물성치 계산 객체(`fluid`)를 생성합니다.
- **초기 물성치 계산**: 변환된 표준 단위 값(V, m, T)과 생성된 `fluid` 객체를 사용하여 탱크의 초기 상태를 계산합니다.
    - 밀도($\rho = m/V$)를 계산합니다.
    - `fluid.GetProps(T, rho)` 메서드를 호출하여 해당 온도, 밀도에서의 상세 물성치(압력, 상 상태, 건도, 각 상 및 혼합물의 u, h, s, cp, cv, c 등)를 포함하는 `Props` 구조체를 얻습니다.
    - 계산된 건도($X$)와 총 질량($m$)을 이용하여 초기 증기 질량($m_v = m \times X$)과 액체 질량($m_l = m \times (1-X)$)을 계산합니다.

# Output

| 명칭         | 기호         | 출력 변수        | 단위    | 비고                               |
| ------------ | ---------- | ------------ | ----- | -------------------------------- |
| 부피         | $V$        | x.tank.V     | m³    | 표준 단위로 변환/계산된 부피               |
| 질량         | $m$        | x.tank.m     | kg    | 표준 단위로 변환된 질량 (총 질량)          |
| 온도         | $T$        | x.tank.T     | K     | 표준 단위로 변환된 온도                  |
| 유체 객체      | -          | x.tank.fluid | -     | 선택된 유체의 물성치 계산 객체             |
| 밀도         | $\rho$      | x.tank.rho   | kg/m³ | 계산된 초기 밀도                       |
| 압력         | $P$        | x.tank.P     | Pa    | 계산된 초기 압력                       |
| 상 상태       | state      | x.tank.state | -     | 유체 상태 (e.g., 'vapor', 'liquid', 'two-phase') |
| 건도         | $X$        | x.tank.X     | -     | 0~1 사이의 값 (이상/액상 영역은 NaN)       |
| 증기 질량     | $m_v$      | x.tank.m_v   | kg    | 계산된 초기 증기 질량 ($m \times X$)      |
| 액체 질량     | $m_l$      | x.tank.m_l   | kg    | 계산된 초기 액체 질량 ($m \times (1-X)$)  |
| 증기상 물성    | $\rho_v, u_v, ...$ | x.tank.rho_v, x.tank.u_v, ... | SI 단위 | 증기 상태 물성치 (Props.rho_v 등)        |
| 액상 물성     | $\rho_l, u_l, ...$ | x.tank.rho_l, x.tank.u_l, ... | SI 단위 | 액체 상태 물성치 (Props.rho_l 등)        |
| 혼합물 물성    | $u, s, h, ...$ | x.tank.u, x.tank.s, ...    | SI 단위 | 평균/혼합물 물성치 (Props.u 등)          |
| 총 엔트로피    | $S$        | x.tank.S     | J/K   | $S = m \times s$                       |
| 총 엔탈피     | $H$        | x.tank.H     | J     | $H = m \times h$                       |

# 전체 코드
```MATLAB
function [x] = Init_Tank(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환
if isfield(u.tank, 'V') % 탱크 부피를 직접 설정한 경우
	switch unit.tank.V
		case "m^3"
			V = u.tank.V;
		case "L"
			V = u.tank.V * 1e-3;
		case "cm^3"
			V = u.tank.V * 1e-6;
		case "ft^3"
			V = u.tank.V * 0.0283168;
		case "gal"
			V = u.tank.V * 3.78541;
		otherwise
			error("허용된 단위: m^3, L, cm^3, ft^3, gal만 입력 가능");
	end
elseif isfield(u.tank, 'd') && isfield(u.tank, 'h') % 원통형 탱크의 직경과 높이로부터 부피 계산
	% 직경 단위 변환
	switch unit.tank.d
		case "m"
			d = u.tank.d;
		case "mm"
			d = u.tank.d * 1e-3;
		case "cm"
			d = u.tank.d * 1e-2;
		case "in"
			d = u.tank.d * 0.0254;
		otherwise
			error("허용된 단위: m, mm, cm, in만 입력 가능");
	end
	
	% 높이 단위 변환
	switch unit.tank.h
		case "m"
			h = u.tank.h;
		case "mm"
			h = u.tank.h * 1e-3;
		case "cm"
			h = u.tank.h * 1e-2;
		case "in"
			h = u.tank.h * 0.0254;
		otherwise
			error("허용된 단위: m, mm, cm, in만 입력 가능");
	end
	
	% 원통형 탱크 부피 계산 (m^3)
	V = pi * (d/2)^2 * h;
    A = pi * (d/2)^2; % <<< 탱크 단면적 계산 추가
else
	error("탱크 부피를 직접 설정하거나 직경과 높이를 설정해야 합니다.");
end

% tank.m, kg
switch unit.tank.m
	case "kg"
		m = u.tank.m;
	case "g"
		m = u.tank.m * 1e-3;
	case "lb"
		m = u.tank.m * 0.453592;
	case "oz"
		m = u.tank.m * 0.0283495;
	otherwise
		error("허용된 단위: kg, g, lb, oz만 입력 가능");
end

% tank.T, K
switch unit.tank.T
	case "K"
		T = u.tank.T;
	case "°C"
		T = u.tank.T + 273.15;
	case "°F"
		T = (u.tank.T - 32) * 5/9 + 273.15;
	case "C"
		T = u.tank.T + 273.15;
	case "F"
		T = (u.tank.T - 32) * 5/9 + 273.15;
	otherwise
		error("허용된 단위: K, °C, °F, C, F만 입력 가능");
end

% tank.fluid
switch u.tank.fluid
	case "N2O"
		fluid = N2O();
	case "CO2"
		fluid = CO2();
	otherwise
		error("N2O, CO2 만 입력 가능");
end


%% 상태량 초기화
% 탱크 상태량 불러오기
x.tank.V = V;
x.tank.A = A; % <<< 계산된 단면적 저장
x.tank.m = m;
x.tank.T = T;
x.tank.fluid = fluid;
x.tank.rho = x.tank.m / x.tank.V;
Props = fluid.GetProps(x.tank.T, x.tank.rho);

% 상태 변수
x.tank.P = Props.P; % 압력
x.tank.state = Props.state; % 상태 변수
x.tank.X = Props.X; % 건도

% 액체 및 증기 질량 계산 및 저장
x.tank.m_v = x.tank.m * x.tank.X;     % 증기 질량
x.tank.m_l = x.tank.m * (1 - x.tank.X); % 액체 질량

% 증기상 물성
x.tank.rho_v = Props.rho_v; % kg/m^3
x.tank.u_v = Props.u_v; % J/kg
x.tank.s_v = Props.s_v; % J/kg-K
x.tank.h_v = Props.h_v; % J/kg
x.tank.cp_v = Props.cp_v; % J/kg-K
x.tank.cv_v = Props.cv_v; % J/kg-K
x.tank.c_v = Props.c_v; % m/s

% 액상 물성
x.tank.rho_l = Props.rho_l; % kg/m^3
x.tank.u_l = Props.u_l; % J/kg
x.tank.s_l = Props.s_l; % J/kg-K
x.tank.h_l = Props.h_l; % J/kg
x.tank.cp_l = Props.cp_l; % J/kg-K
x.tank.cv_l = Props.cv_l; % J/kg-K
x.tank.c_l = Props.c_l; % m/s

% 혼합물 물성
x.tank.u = Props.u; % J/kg
x.tank.s = Props.s; % J/kg-K
x.tank.h = Props.h; % J/kg
x.tank.cp = Props.cp; % J/kg-K
x.tank.cv = Props.cv; % J/kg-K
x.tank.c = Props.c; % m/s
x.tank.S = x.tank.m * Props.s; % J/K
x.tank.H = x.tank.m * Props.h; % J

end