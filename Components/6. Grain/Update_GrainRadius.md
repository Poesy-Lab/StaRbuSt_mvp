---
tags:
  - 그레인
  - 후퇴율
  - 반경 업데이트
Author: SRS 33기 박호진
lastmod: 2024-07-26 # 임시 최종 수정일, 실제 최종 수정일로 변경 필요
---
# 소개
- `Update_GrainRadius.m` 함수는 현재 스텝의 수렴된 후퇴율(`x.fuel.rdot`)과 시간 간격(`x.time.dt`)을 기반으로 다음 시간 스텝의 그레인 내경(`x.fuel.R`)을 업데이트합니다.
- 이 함수는 번아웃 조건을 확인하여 내경이 그레인 외경(`x.fuel.R_out`)을 초과하지 않도록 합니다.
- 또한, **현재 시간 스텝 동안** 발생한 반경 변화량(`x.fuel.dR_m`)과 **현재 시간 스텝 시작 시점의 반경을 기준**으로 계산된 포트 단면적(`x.fuel.Ap`) 및 연소 면적(`x.fuel.Ab`)을 저장합니다.

# Input

| 명칭             | 기호                 | 입력 변수        | 비고                                     |
| ---------------- | ------------------ | ------------ | ---------------------------------------- |
| 현재 스텝 후퇴율     | $\dot{r}_{final}$ | x.fuel.rdot  | [mm/s], 현재 스텝에서 수렴된 값              |
| 시간 간격          | $\Delta t$         | x.time.dt    | [s]                                      |
| **현재 스텝 시작** 내경 | $R_{\text{current}}$ | x.fuel.R     | [m], **이번 스텝 계산 시작 시점의 내경**      |
| 그레인 외경        | $R_{out}$          | x.fuel.R_out | [m], 번아웃 확인용                          |
| 그레인 길이         | $L$                | x.fuel.L     | [m]                                      |

```MATLAB
% Input Extraction 예시 (실제 코드는 아래 전체 코드 참조)
rdot_final_mm_s = x.fuel.rdot; % Converged regression rate
dt = x.time.dt;
R_current = x.fuel.R;       % Radius at the start of the step
R_out = x.fuel.R_out;
L = x.fuel.L;
```

# System

## 1. 반경 변화량 및 다음 스텝 반경 계산
- **1.1 현재 스텝에서의 반경 변화량 계산** (단위: m)
  $$ \Delta R_m = (\dot{r}_{final} \cdot 10^{-3}) \cdot \Delta t $$
```MATLAB
dR_m_final = (rdot_final_mm_s * 1e-3) * dt;
```
- **1.2 이론적인 다음 스텝 반경 계산** (단위: m)
  $$ R_{\text{next}} = R_{\text{current}} + \Delta R_m $$
```MATLAB
R_next_final = R_current + dR_m_final;
```

## 2. 번아웃 조건 확인 및 최종 다음 스텝 반경 결정
- 계산된 `R_next_final`이 그레인 외경 `R_out`보다 크거나 같으면, 다음 스텝 반경을 `R_out`으로 제한합니다.
- 이 경우, 실제 적용된 반경 변화량 `dR_m_final`도 `R_out - R_current` (0 이상)으로 재계산됩니다.
```MATLAB
if R_next_final >= R_out
    R_next_final = R_out; % Cap the radius
    dR_m_final = max(0, R_out - R_current); 
end
```

## 3. 현재 스텝 시작 시점 기준 면적 계산
- 포트 단면적 `Ap`와 연소 면적 `Ab`는 **현재 스텝 시작 시점의 내경** `R_current`를 기준으로 계산됩니다. 이 값들은 현재 스텝의 유량 및 후퇴율 계산에 사용된 기하학적 형상에 해당합니다.
- **3.1 현재 스텝 시작 기준 포트 단면적** (단위: m²)
  $$ A_p = \pi R_{\text{current}}^2 $$
```MATLAB
Ap_current = pi * R_current^2;
```
- **3.2 현재 스텝 시작 기준 연소 표면적** (단위: m²)
  $$ A_b = 2 \pi R_{\text{current}} L $$
```MATLAB
Ab_current = 2 * pi * R_current * L;
```

# Output

| 명칭                 | 기호              | 출력 변수        | 비고                                       |
| -------------------- | --------------- | ------------ | ------------------------------------------ |
| **다음 스텝** 연료 포트 반경 | $R_{\text{next}}$ | x.fuel.R     | [m], **다음 시간 스텝에 사용될 업데이트된 내경**   |
| **현재 스텝** 반경 변화량 | $\Delta R_m$     | x.fuel.dR_m  | [m], **이번 시간 스텝 동안의 실제 반경 변화**   |
| **현재 스텝 시작** 포트 단면적 | $A_p$           | x.fuel.Ap    | [m²], **이번 스텝 계산 시작 시점의 `R` 기준**  |
| **현재 스텝 시작** 연소 표면적 | $A_b$           | x.fuel.Ab    | [m²], **이번 스텝 계산 시작 시점의 `R` 기준**  |

```MATLAB
% Output Update
x.fuel.R = R_next_final;     % Updated radius for the NEXT step
x.fuel.dR_m = dR_m_final;    % Change in radius DURING this step
x.fuel.Ap = Ap_current;      % Port area at the START of this step
x.fuel.Ab = Ab_current;      % Burn area at the START of this step
```

# 전체 코드
```MATLAB
function [x] = Update_GrainRadius(x)
%Update_GrainRadius Updates the grain radius for the next time step.
%   Calculates the radius change based on the current regression rate and dt,
%   updates the radius for the next step (checking for burnout), and stores
%   the radius change (dR_m) and the areas (Ap, Ab) based on the radius
%   at the *start* of this time step.
%
% Inputs:
%   x: Structure containing current system state, must include:
%       x.fuel.rdot: Converged regression rate for the current step (mm/s)
%       x.time.dt: Time step (s)
%       x.fuel.R: Inner radius at the *start* of the current step (m)
%       x.fuel.R_out: Outer radius (m)
%       x.fuel.L: Grain length (m)
%
% Outputs:
%   x: Updated structure with:
%       x.fuel.R: Updated inner radius for the *next* time step (m)
%       x.fuel.dR_m: Change in radius during *this* time step (m)
%       x.fuel.Ap: Port area based on radius at the *start* of this step (m^2)
%       x.fuel.Ab: Burn area based on radius at the *start* of this step (m^2)

%% Input Extraction
rdot_final_mm_s = x.fuel.rdot; % Converged regression rate from the calling function
dt = x.time.dt;
R_current = x.fuel.R; % Radius at the start of the step
R_out = x.fuel.R_out;
L = x.fuel.L;

%% Calculate Radius Update
% Calculate the change for this dt based on the converged rate
dR_m_final = (rdot_final_mm_s * 1e-3) * dt; 
% Calculate the theoretical next radius
R_next_final = R_current + dR_m_final;

% Check for fuel burnout
if R_next_final >= R_out
    R_next_final = R_out; % Cap the radius
    % Calculate the actual change applied if capped
    dR_m_final = max(0, R_out - R_current); 
    % Note: rdot might have been non-zero to cause this, but for the next step,
    % the radius is capped. The stored rdot reflects the rate *during* the step.
end

%% Calculate Areas based on STARTING Radius
% These areas correspond to the geometry used for the calculations *within* the step
Ap_current = pi * R_current^2; 
Ab_current = 2 * pi * R_current * L;

%% Update Output Structure
% Store the radius for the NEXT step
x.fuel.R = R_next_final; 
% Store the change that occurred IN this step
x.fuel.dR_m = dR_m_final; 
% Store the areas calculated with the radius at the START of the step
x.fuel.Ap = Ap_current; 
x.fuel.Ab = Ab_current;

end 