---
tags:
  - 노즐
  - 초기화
---
# 소개
- `Init_Nozzle` 함수는 로켓 노즐의 기하학적 형상 및 성능 관련 파라미터를 초기화합니다.
- 사용자는 노즐 목 직경(`Dt`), 출구 직경(`De` 또는 면적비 `eps`), 반각(`alpha`), 출구 각도(`theta_e`, 선택 사항), 추력 효율(`eta`)을 입력합니다.
- 입력된 치수 및 각도는 표준 단위(m, radian)로 변환됩니다.
- 출구 직경(`De`)은 직접 입력하거나 면적비(`eps`)를 통해 계산될 수 있습니다.
- 반각과 출구 각도를 이용하여 노즐 형상 보정 계수($\lambda$)를 계산합니다.
- 계산된 값들을 로컬 구조체에 저장하여 반환합니다.

# Input

| 구분   | 명칭       | 기호       | 입력 변수       | 단위/옵션       | 비고                                    |
| ---- | -------- | -------- | ------------- | ----------- | ------------------------------------- |
| 형상   | 목 직경    | $D_t$    | u.nozzle.Dt   | m, mm, cm, in | 노즐 목(throat) 직경                       |
|      | 출구 직경   | $D_e$    | u.nozzle.De   | m, mm, cm, in | 노즐 출구(exit) 직경 (eps 입력 시 무시)        |
|      | 면적비     | $\epsilon$ | u.nozzle.eps  | -           | 출구/목 면적비 ($A_e/A_t$) (De 입력 시 무시) |
| 각도   | 반각       | $\alpha$  | u.nozzle.alpha| degree, radian| 노즐 팽창부 반각 (cone half-angle)       |
|      | 출구 각도   | $\theta_e$ | u.nozzle.theta_e| degree, radian| 노즐 출구 각도 (선택 사항, 미입력 시 $\alpha$ 사용) |
| 성능   | 추력 효율   | $\eta$    | u.nozzle.eta  | -           | 노즐 추력 효율 (0~1)                    |

# System
- **목 직경 변환**: `switch` 문을 사용하여 `u.nozzle.Dt`의 단위를 m으로 변환합니다.
- **출구 직경 결정/변환**: `isfield` 함수로 사용자가 출구 직경(`De`)을 직접 입력했는지 확인합니다.
    - `De` 입력 시: `switch` 문을 사용하여 입력된 단위를 m으로 변환합니다.
    - `De` 미입력 시: 면적비(`u.nozzle.eps`)와 변환된 목 직경(`Dt`)을 사용하여 출구 직경($D_e = D_t \sqrt{\epsilon}$)을 계산합니다. (`eps` 필드가 없으면 에러 발생 가능성 있음 - 코드 보완 필요)
- **각도 변환**: `alpha`와 (존재한다면) `theta_e`의 단위를 확인하고 `switch` 문을 사용하여 radian으로 변환합니다.
- **형상 보정 계수 계산**: 노즐 형상 보정 계수 $\lambda = \frac{1}{2}(1 + \cos\beta)$를 계산합니다.
    - $\beta = (\alpha + \theta_e) / 2$ (만약 `theta_e`가 입력된 경우)
    - $\beta = \alpha$ (만약 `theta_e`가 입력되지 않은 경우)
- **상태량 초기화**: 계산/변환된 값들을 로컬 구조체 `x_nozzle.nozzle`의 필드에 저장합니다.

# Output

| 명칭        | 기호       | 출력 변수            | 단위/값 | 비고                               |
| --------- | -------- | ---------------- | ----- | -------------------------------- |
| 목 직경     | $D_t$    | x_nozzle.nozzle.Dt | m     | 표준 단위로 변환된 목 직경                 |
| 출구 직경    | $D_e$    | x_nozzle.nozzle.De | m     | 표준 단위로 변환/계산된 출구 직경            |
| 목 면적     | $A_t$    | x_nozzle.nozzle.At | m²    | 계산된 목 면적                        |
| 출구 면적    | $A_e$    | x_nozzle.nozzle.Ae | m²    | 계산된 출구 면적                      |
| 면적비      | $\epsilon$ | x_nozzle.nozzle.eps| -     | 입력된 면적비 값                         |
| 추력 효율    | $\eta$    | x_nozzle.nozzle.eta| -     | 입력된 추력 효율 값                      |
| 형상 보정 계수 | $\lambda$ | x_nozzle.nozzle.lambda| -     | 계산된 노즐 형상 보정 계수($\lambda = \frac{1}{2}(1 + \cos\beta)$) |

# 전체 코드
```MATLAB
function [x_nozzle] = Init_Nozzle(u, unit) % 입력 변경
x_nozzle = struct(); % 로컬 구조체 초기화

%% 입력값 변환
% nozzle.Dt, m
switch unit.nozzle.Dt
	case "m"
		Dt = u.nozzle.Dt;
	case "mm"
		Dt = u.nozzle.Dt * 1e-3;
	case "cm"
		Dt = u.nozzle.Dt * 1e-2;
	case "in"
		Dt = u.nozzle.Dt * 0.0254;
	otherwise
		error("허용된 단위: m, mm, cm, in만 입력 가능");
end

if isfield(u.nozzle, 'De') % 노즐 출구 직경을 직접 설정한 경우
	switch unit.nozzle.De % nozzle.De, m
		case "m"
			De = u.nozzle.De;
		case "mm"
			De = u.nozzle.De * 1e-3;
		case "cm"
			De = u.nozzle.De * 1e-2;
		case "in"
			De = u.nozzle.De * 0.0254;
		otherwise
			error("허용된 단위: m, mm, cm, in만 입력 가능");
	end
	% 출구 직경으로 면적비 계산 (만약 eps가 없거나 다르면 업데이트)
	eps_calc = (De/Dt)^2;
	if ~isfield(u.nozzle, 'eps') || abs(u.nozzle.eps - eps_calc) > 1e-9 % 부동 소수점 비교 오차 고려
		 u.nozzle.eps = eps_calc; % u 구조체를 직접 수정하는 것은 바람직하지 않을 수 있음 -> 추후 검토 필요
	end
elseif isfield(u.nozzle, 'eps') % 노즐 면적 확장비로부터 면적 계산
	De = sqrt(u.nozzle.eps) * Dt;
else
    error("노즐 출구 직경(De) 또는 면적비(eps) 중 하나는 반드시 입력해야 합니다.");
end

switch unit.nozzle.alpha
	case "degree"
		alpha = u.nozzle.alpha * pi/180;
	case "radian"
		alpha = u.nozzle.alpha;
	otherwise
	    error("허용된 노즐 반각 단위: degree, radian"); % 에러 메시지 추가
end

if isfield(u.nozzle, 'theta_e')
	switch unit.nozzle.theta_e
		case "degree"
			theta_e = u.nozzle.theta_e * pi/180;
			beta = (alpha + theta_e) / 2;
		case "radian"
			theta_e = u.nozzle.theta_e;
			beta = (alpha + theta_e) / 2;
		otherwise
			error("허용된 단위: degree, radian 만 입력 가능")
	end
else
	beta = alpha;
end

%% 상태량 초기화
x_nozzle.nozzle.Dt = Dt; % m
x_nozzle.nozzle.De = De; % m
x_nozzle.nozzle.At = pi*(Dt/2)^2; % m^2, 목 면적 추가
x_nozzle.nozzle.Ae = pi*(De/2)^2; % m^2, 출구 면적 추가
x_nozzle.nozzle.eps = u.nozzle.eps; % Note: u.nozzle.eps might have been modified above
x_nozzle.nozzle.eta = u.nozzle.eta;
x_nozzle.nozzle.lambda = 1/2 * (1 + cos(beta));

end