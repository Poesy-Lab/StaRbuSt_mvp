---
tags:
  - 연료
  - 초기화
lastmod: 2025-04-30
---
# 소개
- `Init_Fuel` 함수는 하이브리드 로켓의 고체 연료 그레인 관련 초기 설정을 수행합니다.
- 사용자는 연료 종류(`card`), 밀도(선택 사항), 초기 포트 반경(`R`), **그레인 외경(`R_out`)**, 길이(`L`), 포트 개수(`N`), 연소율 계수(`a`, `n`), **그리고 사용할 후퇴율 모델(`model`)** 을 입력합니다.
- 연료 종류(`card`)에 따라 CEA 입력 카드를 생성하고 기본 밀도를 설정합니다. 사용자가 밀도를 직접 입력하면 해당 값을 우선 사용합니다.
- 입력된 기하학적 치수(`R`, `R_out`, `L`)는 표준 단위(m)로 변환됩니다.
- **외경(`R_out`)이 내경(`R`)보다 크거나 같은지 유효성 검사를 수행합니다.**
- 변환된 값들을 사용하여 초기 포트 단면적(`Ap`)과 초기 연소 표면적(`Ab`)을 계산합니다.
- **입력된 후퇴율 모델 문자열은 유효성 검사 후 저장됩니다.**

# Input

| 구분     | 명칭        | 기호 | 입력 변수      | 단위/옵션               | 비고                                     |
| -------- | --------- | -- | ------------ | --------------------- | -------------------------------------- |
| 종류     | 연료 카드     | -  | u.fuel.card  | HDPE, HTPB, Paraffin            | 연료 종류 선택 (CEA 카드 생성 및 기본 밀도 설정) |
| 물성     | 밀도        | ρ  | u.fuel.rho   | kg/m³, g/cm³, lb/ft³   | 선택 사항, 입력 시 card 기본값 무시         |
| 형상     | 초기 포트 반경 | R  | u.fuel.R     | m, mm, cm, in         | 연료 그레인 초기 포트 반경                   |
| **형상** | **그레인 외경**| **R_out** | **u.fuel.R_out** | **m, mm, cm, in**     | **연료 그레인 외경 (R_out >= R 필수)**     |
|          | 길이        | L  | u.fuel.L     | m, mm, cm, in         | 연료 그레인 길이                         |
|          | 포트 개수     | N  | u.fuel.N     | -                     | 연료 그레인 포트 개수                      |
| 연소 특성 | 연소율 계수   | a  | u.fuel.a     | -                     | 후퇴율 식 ($aG_{ox}^n$)의 계수 $a$            |
|          | 연소율 지수   | n  | u.fuel.n     | -                     | 후퇴율 식 ($aG_{ox}^n$)의 지수 $n$            |
| **모델** | **후퇴율 모델** | -  | **u.fuel.model** | **문자열 (예: "aGn")**  | **사용할 후퇴율 모델 이름 (현재 "aGn"만 유효)** |

# System
- **연료 카드 및 기본 밀도 설정**: `switch` 문을 사용하여 `u.fuel.card` 값에 따라 CEA 입력 카드 문자열(`card`)을 생성하고, 해당 연료의 기본 밀도(`default_rho_g_cm3`)를 설정합니다.
- **밀도 결정 및 변환**: `isfield` 함수로 사용자가 밀도(`u.fuel.rho`)를 입력했는지 확인합니다.
    - 입력 시: 해당 단위(`unit.fuel.rho`)를 확인하고 `switch` 문을 사용하여 kg/m³로 변환하여 `rho` 변수에 저장합니다.
    - 미입력 시: `card`에서 설정된 `default_rho_g_cm3` 값을 kg/m³로 변환하여 `rho` 변수에 저장합니다.
- **기하학적 치수 변환**: `R`, `R_out`, `L`의 단위를 확인하고 `switch` 문을 사용하여 각각 m 단위로 변환합니다.
- **외경 유효성 검사**: 변환된 `R_out`이 `R`보다 작으면 오류를 발생시킵니다.
- **면적 계산**: 변환된 `R`과 `L`을 사용하여 초기 포트 단면적($A_p = \pi R^2$)과 초기 연소 표면적($A_b = 2 \pi R L$)을 계산합니다.
- **후퇴율 모델 처리**: `isfield` 함수로 사용자가 모델(`u.fuel.model`)을 입력했는지 확인합니다.
    - 입력 시: 문자열로 변환하고 현재 유효한 모델("aGn")인지 확인합니다. 유효하지 않으면 경고를 표시하고 기본값("aGn")을 사용합니다.
    - 미입력 시: 경고를 표시하고 기본값("aGn")을 사용합니다.
    - 최종 선택된 모델 문자열을 `x.fuel.model`에 저장합니다.

# Output

| 명칭        | 기호 | 출력 변수     | 단위   | 비고                            |
| --------- | -- | ----------- | ---- | ----------------------------- |
| 포트 단면적   | $A_p$ | x.fuel.Ap   | m²   | 계산된 초기 포트 단면적             |
| 연소 표면적   | $A_b$ | x.fuel.Ab   | m²   | 계산된 초기 연소 표면적             |
| 포트 반경    | R  | x.fuel.R    | m    | 표준 단위로 변환된 초기 포트 반경       |
| **그레인 외경**| **R_out**| **x.fuel.R_out**| **m**  | **표준 단위로 변환된 그레인 외경**    |
| 밀도        | ρ  | x.fuel.rho  | kg/m³ | 결정 및 변환된 연료 밀도              |
| 포트 개수     | N  | x.fuel.N    | -    | 입력된 포트 개수                    |
| 연소율 계수   | a  | x.fuel.a    | -    | 입력된 연소율 계수 $a$              |
| 연소율 지수   | n  | x.fuel.n    | -    | 입력된 연소율 지수 $n$              |
| 연료 카드     | -  | x.fuel.card | -    | 생성된 CEA 입력 카드 문자열         |
| **후퇴율 모델** | -  | **x.fuel.model**| **문자열** | **선택/저장된 후퇴율 모델 이름 ("aGn")** |

# 전체 코드
```MATLAB
function [x] = Init_Fuel(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환
% fuel.card
switch u.fuel.card
	case 'HDPE'
		card = ['fuel (CH2)x(cr) C 1.0 H 2.0 wt%=100.0', newline, ...
		'h,cal = -6188.6 t(k) = 298.15 rho = 0.935']; % h: cal/mol, rho: g/cm^3
		default_rho_g_cm3 = 0.935;
	case 'HTPB'
		card = ['fuel R-45(HTPB FROM_RPL_DATA) C 7.3165 H 10.3360 O 0.1063    wt%=100.00', newline, ...
		'h,cal= 1200.0 t(k)=298.15 rho=0.9220']; % h: cal/mol, rho: g/cm^3
		default_rho_g_cm3 = 0.9220;
    case 'Paraffin' % 추가된 케이스
        % Using C12H24 surrogate for paraffin: Hf = –92 200 cal/mol at 298 K, rho ≈ 0.900 g/cm³
        card = ['fuel C12H24(cr) C 12.0 H 24.0 wt%=100.00', newline, ...
                'h,cal = -92200.0 t(k) = 298.15 rho = 0.900']; % surrogate model
        default_rho_g_cm3 = 0.900;
	otherwise
		error("허용 추진제: HDPE, HTPB, Paraffin 만 입력 가능") % 오류 메시지 업데이트
end

% fuel.rho, kg/m³
if isfield(u.fuel, 'rho') % 사용자가 밀도를 입력한 경우
	switch unit.fuel.rho
		case "kg/m^3"
			rho = u.fuel.rho;
		case "g/cm^3"
			rho = u.fuel.rho * 1e3;
		case "lb/ft^3"
			rho = u.fuel.rho * 16.0185;
		otherwise
			error("허용된 단위: kg/m^3, g/cm^3, lb/ft^3만 입력 가능");
	end
else % 사용자가 밀도를 입력하지 않은 경우, card의 기본 밀도 사용
	rho = default_rho_g_cm3 * 1e3; % g/cm^3 -> kg/m^3
end

% fuel.R, m
switch unit.fuel.R
	case "m"
		R = u.fuel.R;
	case "mm"
		R = u.fuel.R * 1e-3;
	case "cm"
		R = u.fuel.R * 1e-2;
	case "in"
		R = u.fuel.R * 0.0254;
	otherwise
		error("허용된 단위: m, mm, cm, in만 입력 가능");
end

% fuel.R_out, m (Outer Radius)
if isfield(u.fuel, 'R_out')
    switch unit.fuel.R_out
        case "m"
            R_out = u.fuel.R_out;
        case "mm"
            R_out = u.fuel.R_out * 1e-3;
        case "cm"
            R_out = u.fuel.R_out * 1e-2;
        case "in"
            R_out = u.fuel.R_out * 0.0254;
        otherwise
            error("허용된 외경 단위: m, mm, cm, in만 입력 가능");
    end
    % Validate R_out >= R
    if R_out < R
        error('Init_Fuel:InvalidRadius', 'Outer radius (R_out=%.4f m) must be greater than or equal to inner radius (R=%.4f m).', R_out, R);
    end
else
    error('Init_Fuel:MissingOuterRadius', 'Outer radius (u.fuel.R_out) must be specified.');
end

% fuel.L, m
switch unit.fuel.L
	case "m"
		L = u.fuel.L;
	case "mm"
		L = u.fuel.L * 1e-3;
	case "cm"
		L = u.fuel.L * 1e-2;
	case "in"
		L = u.fuel.L * 0.0254;
	otherwise
		error("허용된 단위: m, mm, cm, in만 입력 가능");
end

% fuel.model
if isfield(u.fuel, 'model')
    model_str = string(u.fuel.model); % Ensure string type
    % Basic validation (currently only checks for "aGn")
    if ~contains(model_str, "aGn", "IgnoreCase", true)
        warning('Init_Fuel:UnknownModel', 'Unknown fuel model specified: "%s". Defaulting to "aGn".', model_str);
        model_str = "aGn"; % Default to aGn if unknown
    end
else
    warning('Init_Fuel:NoModel', 'Fuel regression model not specified (u.fuel.model). Defaulting to "aGn".');
    model_str = "aGn"; % Default to aGn if not specified
end

%% 상태량 초기화
x.fuel.Ap = pi * (R)^2; % m^2, 초기 포트 단면적
x.fuel.Ab = 2 * pi * R * L; % m^2, 초기 연소 표면적
x.fuel.R = R; % m, 현재 포트 반경 (초기값)
x.fuel.rho = rho; % kg/m^3, 연료 밀도
x.fuel.N = u.fuel.N; % 포트 개수
x.fuel.a = u.fuel.a; % 연소율 계수 a
x.fuel.n = u.fuel.n; % 연소율 지수 n
x.fuel.card = card; % CEA 카드 문자열
x.fuel.model = model_str; % 사용할 후퇴율 모델 이름 ("aGn" 등)
x.fuel.R_out = R_out; % m, 그레인 외경 추가
x.fuel.L = L;      % m, 그레인 길이 추가

end