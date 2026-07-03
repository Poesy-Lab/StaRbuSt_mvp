---
tags:
  - 벤트포트
  - 초기화
---
# 소개
- `Init_Vent` 함수는 탱크 벤트 포트의 초기 설정을 담당합니다.
- 사용자는 벤트 포트의 면적(직접 또는 직경 입력)과 해석 모델 **문자열**, 토출 계수, 작동 모드를 지정할 수 있습니다.
- 입력된 형상 정보(면적 또는 직경)는 표준 단위(m², m)로 변환되며, 직경 입력 시 원형 면적이 계산됩니다.
- **해석 모델은 입력된 문자열 그대로 저장됩니다.**

# Input

| 구분   | 명칭     | 기호   | 입력 변수    | 단위/옵션                             | 비고                                  |
| ---- | ------ | ---- | -------- | ----------------------------------- | ----------------------------------- |
| 형상   | 면적     | A    | u.vent.A | m², mm², cm², in²                   | 벤트 포트 면적 직접 입력 (d 입력 시 무시)           |
|      | 직경     | d    | u.vent.d | m, mm, cm, in                       | 원형 벤트 포트 직경 (A 입력 시 무시)            |
| 모델   | 해석 모델  | -    | u.vent.model | **문자열 (예: "ICF", "CdA")**       | 벤트 포트 유동 해석 모델 선택 (ICF 또는 CdA 포함 권장) |
| 계수   | 토출 계수  | Cd   | u.vent.Cd  | -                                   | 벤트 포트 토출 계수 (0~1)                 |
| 설정   | 작동 모드  | mode | u.vent.mode  | 0, 1                                | 0: 벤트포트 비활성, 1: 벤트포트 활성           |

# System
- **면적 계산/변환**: `isfield` 함수로 사용자가 면적(`A`)을 직접 입력했는지, 직경(`d`)을 입력했는지 확인합니다.
    - `A` 입력 시: `switch` 문을 사용하여 입력된 단위를 m²로 변환합니다.
    - `d` 입력 시: 직경 단위를 m으로 변환한 후, 원형 면적 공식 ($A = \pi d^2 / 4$)을 사용하여 m² 단위의 면적을 계산합니다.
    - 면적 또는 직경 정보가 없으면 에러를 발생시킵니다.
- **모델 문자열 저장**: 입력된 `u.vent.model` 문자열을 `string` 타입으로 변환하여 그대로 `x.vent.model`에 저장합니다. 기본적인 유효성 검사(ICF 또는 CdA 포함 여부)가 수행됩니다.
- **기타 값 전달**: 토출 계수(`u.vent.Cd`)와 작동 모드(`u.vent.mode`)는 별도 변환 없이 그대로 전달됩니다.

# Output

| 명칭     | 기호   | 출력 변수     | 단위/값          | 비고                           |
| ------ | ---- | --------- | -------------- | ---------------------------- |
| 면적     | A    | x.vent.A  | m²             | 표준 단위로 변환/계산된 면적           |
| 해석 모델  | -    | x.vent.model| **문자열**       | **입력된 모델 문자열 (예: "ICF")** |
| 토출 계수  | Cd   | x.vent.Cd | -              | 입력된 토출 계수 값                |
| 작동 모드  | mode | x.vent.mode | 0 또는 1       | 입력된 작동 모드 값                |

# 전체 코드
```MATLAB
function [x] = Init_Vent(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환
if isfield(u.vent, 'A') % 벤트 포트 면적을 직접 설정한 경우
	switch unit.vent.A
		case "m^2"
			A = u.vent.A;
		case "mm^2"
			A = u.vent.A * 1e-6;
		case "cm^2"
			A = u.vent.A * 1e-4;
		case "in^2"
			A = u.vent.A * 0.00064516;
		otherwise
			error("허용된 단위: m^2, mm^2, cm^2, in^2만 입력 가능");
	end
elseif isfield(u.vent, 'd') % 벤트 포트의 직경으로부터 면적 계산
	switch unit.vent.d
		case "m"
			d = u.vent.d;
		case "mm"
			d = u.vent.d * 1e-3;
		case "cm"
			d = u.vent.d * 1e-2;
		case "in"
			d = u.vent.d * 0.0254;
		otherwise
			error("허용된 단위: m, mm, cm, in만 입력 가능");
	end
	A = (pi/4)*(d)^2; % 원형 벤트 포트 면적 계산 (m^2)
else
	error("벤트 포트 면적을 직접 설정하거나 직경을 설정해야 합니다.");
end

% vent.model - Store the model string directly
model_str = string(u.vent.model); % Ensure it's a string type

% Basic validation: Check if the input string contains known keywords
if ~(contains(model_str, "ICF", "IgnoreCase", true) || contains(model_str, "CdA", "IgnoreCase", true))
    warning('Init_Vent:UnknownModel', 'Unknown vent model string: "%s". Ensure PreFeed/other functions handle this.', model_str);
    % Keep the original string, let downstream functions decide behavior
end

%% 상태량 초기화
x.vent.A = A; % 벤트포트 면적 (m^2)
x.vent.model = model_str; % 벤트포트 해석 모델 문자열 ("ICF" 또는 "CdA" 포함 예상)
x.vent.Cd = u.vent.Cd; % 토출계수
x.vent.mode = u.vent.mode; % 0: 벤트포트 없음, 1: 벤트포트 있음

end 
```