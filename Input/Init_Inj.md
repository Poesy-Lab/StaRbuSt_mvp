---
tags:
  - 인젝터
  - 초기화
---
# 소개
- `Init_Inj` 함수는 인젝터의 초기 설정을 수행합니다.
- 사용자는 개별 인젝터 오리피스의 면적(직접 또는 직경)과 개수(`n`), 토출 계수(`Cd`), 그리고 액상 및 기상 공급 시 사용할 유동 해석 **모델 이름(문자열)**을 지정합니다.
- 입력된 개별 오리피스 형상 정보(면적 또는 직경)는 표준 단위(m², m)로 변환되어 면적이 계산됩니다.
- 계산된 개별 오리피스 면적에 개수(`n`)를 곱하여 총 인젝터 면적(`x.inj.A`)을 초기화합니다.
- **액상 및 기상 공급 모델 이름은 입력된 문자열 그대로 저장됩니다.** (간단한 유효성 검사 포함 가능)

# Input

| 구분   | 명칭         | 기호   | 입력 변수         | 단위/옵션                          | 비고                                    |
| ---- | ---------- | ---- | ------------- | -------------------------------- | ------------------------------------- |
| 형상   | 개별 오리피스 면적 | $A_{orifice}$ | u.inj.A       | m², mm², cm², in²                | 개별 오리피스 면적 직접 입력 (d 입력 시 무시)      |
|      | 개별 오리피스 직경 | $d_{orifice}$ | u.inj.d       | m, mm, cm, in                    | 원형 오리피스 직경 (A 입력 시 무시)             |
|      | 오리피스 개수   | n    | u.inj.n       | -                                | 인젝터 오리피스 총 개수                   |
| 계수   | 토출 계수      | Cd   | u.inj.Cd      | -                                | 인젝터 토출 계수 (0~1)                    |
| 모델   | 액상 공급 모델   | -    | u.inj.model_LiqFeed | **문자열 (예: "NHNE", "CdA")** | 액상 상태 유체 공급 시 해석 모델 이름      |
|      | 기상 공급 모델   | -    | u.inj.model_VapFeed | **문자열 (예: "ICF", "CdA")**  | 기상 상태 유체 공급 시 해석 모델 이름      |

# System
- **개별 오리피스 면적 계산/변환**: `isfield` 함수로 사용자가 개별 면적(`A`)을 직접 입력했는지, 직경(`d`)을 입력했는지 확인합니다.
    - `A` 입력 시: `switch` 문을 사용하여 입력된 단위를 m²로 변환합니다.
    - `d` 입력 시: 직경 단위를 m으로 변환한 후, 원형 면적 공식 ($A_{orifice} = \pi d^2 / 4$)을 사용하여 m² 단위의 면적을 계산합니다.
    - 면적 또는 직경 정보가 없으면 에러를 발생시킵니다.
- **모델 문자열 저장**: `u.inj.model_LiqFeed` 및 `u.inj.model_VapFeed` 문자열을 `string` 타입으로 변환하여 그대로 `x.inj.model_LiqFeed` 및 `x.inj.model_VapFeed`에 저장합니다. (간단한 유효성 검사 수행 가능)
- **총 면적 계산**: 계산/변환된 개별 오리피스 면적(`A`)에 오리피스 개수(`u.inj.n`)를 곱하여 총 인젝터 면적을 계산합니다.
- **기타 값 전달**: 토출 계수(`u.inj.Cd`)는 별도 변환 없이 그대로 전달됩니다.

# Output

| 명칭         | 기호 | 출력 변수          | 단위/값    | 비고                                      |
| ---------- | -- | -------------- | -------- | --------------------------------------- |
| 총 인젝터 면적 | $A_{inj}$ | x.inj.A        | m²       | 계산된 총 인젝터 면적 ($A_{inj} = n \times A_{orifice}$) |
| 토출 계수    | Cd | x.inj.Cd       | -        | 입력된 토출 계수 값                       |
| 액상 공급 모델 | -  | x.inj.model_LiqFeed| **문자열** | **저장된 액상 공급 모델 이름 (예: "NHNE")** |
| 기상 공급 모델 | -  | x.inj.model_VapFeed| **문자열** | **저장된 기상 공급 모델 이름 (예: "ICF")**  |

# 전체 코드
```MATLAB
function [x] = Init_Inj(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환
if isfield(u.inj, 'A') % 인젝터 면적을 직접 설정한 경우
	switch unit.inj.A
		case "m^2"
			A = u.inj.A;
		case "mm^2"
			A = u.inj.A * 1e-6;
		case "cm^2"
			A = u.inj.A * 1e-4;
		case "in^2"
			A = u.inj.A * 0.00064516;
		otherwise
			error("허용된 단위: m^2, mm^2, cm^2, in^2만 입력 가능");
	end
elseif isfield(u.inj, 'd') % 인젝터의 직경으로부터 면적 계산
	switch unit.inj.d
		case "m"
			d = u.inj.d;
		case "mm"
			d = u.inj.d * 1e-3;
		case "cm"
			d = u.inj.d * 1e-2;
		case "in"
			d = u.inj.d * 0.0254;
		otherwise
			error("허용된 단위: m, mm, cm, in만 입력 가능");
	end
	A = (pi/4) * (d)^2; % 개별 오리피스 단면적 계산 (m^2)
else
	error("인젝터 면적을 직접 설정하거나 직경을 설정해야 합니다.");
end

% inj.model_LiqFeed - Store the string
if isfield(u.inj, 'model_LiqFeed')
    model_LiqFeed_str = string(u.inj.model_LiqFeed); % Ensure string type
    % Add basic validation if needed (e.g., check for known keywords)
    if ~(contains(model_LiqFeed_str, "NHNE", "IgnoreCase", true) || contains(model_LiqFeed_str, "CdA", "IgnoreCase", true))
        warning('Init_Inj:UnknownLiqModel', 'Unknown liquid feed model: %s', model_LiqFeed_str);
    end
else
    error('Missing input: u.inj.model_LiqFeed is required.'); % Require the input
end

% inj.model_VapFeed - Store the string
if isfield(u.inj, 'model_VapFeed')
    model_VapFeed_str = string(u.inj.model_VapFeed); % Ensure string type
    % Add basic validation if needed
    if ~(contains(model_VapFeed_str, "ICF", "IgnoreCase", true) || contains(model_VapFeed_str, "CdA", "IgnoreCase", true))
         warning('Init_Inj:UnknownVapModel', 'Unknown vapor feed model: %s', model_VapFeed_str);
    end
else
     error('Missing input: u.inj.model_VapFeed is required.'); % Require the input
end

%% 상태량 초기화
x.inj.A = u.inj.n * A; % 총 인젝터 면적 (m^2)
x.inj.Cd = u.inj.Cd; % 토출 계수
x.inj.model_LiqFeed = model_LiqFeed_str; % 액상 공급 모델 이름 (문자열)
x.inj.model_VapFeed = model_VapFeed_str; % 기상 공급 모델 이름 (문자열)

end