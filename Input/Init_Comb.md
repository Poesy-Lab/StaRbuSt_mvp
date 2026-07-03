---
tags:
  - 연소실
  - 초기화
---
# 소개
- `Init_Comb` 함수는 연소실 관련 초기 설정을 수행합니다.
- 현재는 연소 성능을 나타내는 지표 중 하나인 **특성 속도 효율($\eta_{c^*}$)** 값을 입력받아 로컬 구조체에 저장하여 반환합니다.

# Input

| 명칭        | 기호         | 입력 변수     | 비고             |
| --------- | ---------- | --------- | -------------- |
| 특성 속도 효율 | $\eta_{c^*}$ | u.comb.eta | 0~1 사이의 값 (이상적일수록 1에 가까움) |

# System
- 입력받은 `u.comb.eta` 값을 로컬 구조체 `x_comb.comb.eta`에 그대로 할당합니다.
- 별도의 단위 변환이나 계산 과정은 없습니다.

# Output

| 명칭        | 기호         | 출력 변수          | 단위/값 | 비고          |
| --------- | ---------- | ---------------- | ----- | ----------- |
| 특성 속도 효율 | $\eta_{c^*}$ | x_comb.comb.eta | -     | 입력된 값 그대로 |

# 전체 코드
```MATLAB
function [x_comb] = Init_Comb(u, unit) % unit은 사용되지 않지만 통일성을 위해 유지
%% 입력값 변환
% comb.R_comb, m (연소실 반경)
if isfield(u.comb, 'R_comb') % 사용자가 연소실 반경을 입력한 경우
    if isfield(unit, 'comb') && isfield(unit.comb, 'R_comb') % 단위 정보가 있는지 확인
        switch unit.comb.R_comb
            case "m"
                R_comb = u.comb.R_comb;
            case "mm"
                R_comb = u.comb.R_comb * 1e-3;
            case "cm"
                R_comb = u.comb.R_comb * 1e-2;
            case "in"
                R_comb = u.comb.R_comb * 0.0254;
            otherwise
                error("Init_Comb:InvalidUnitRcomb", "허용된 연소실 반경 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.comb.R_comb);
        end
    else
        warning('Init_Comb:MissingUnitRcomb', '연소실 반경 단위 (unit.comb.R_comb)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
        R_comb = u.comb.R_comb; % 단위 정보가 없으면 기본 단위(m)로 가정
    end
else
    error('Init_Comb:MissingRcomb', '연소실 반경 (u.comb.R_comb)이(가) 입력되지 않았습니다.');
    % 또는 필요에 따라 기본값을 설정할 수도 있습니다.
    % R_comb = defaultValue; 
end

% 특별한 단위 변환 없음

x_comb = struct(); % 로컬 구조체 초기화

%% 상태량 초기화
x_comb.comb.eta = u.comb.eta; % 특성속도 효율 (0~1)
x_comb.comb.R_comb = R_comb; % m, 변환된 연소실 반경 저장

end