---
tags:
  - EOS
  - 상태방정식
  - 유체
  - 추상클래스
---
# 소개 
- `FluidEOS`는 열역학적 상태 계산을 위한 추상 클래스(Abstract class)로, 다양한 유체의 상태방정식을 구현하기 위한 기반 클래스이다.
- 이 클래스는 임계점 상수, 이상기체 헬름홀츠 에너지 계수, 잔여 헬름홀츠 에너지 계수 등 유체 특성치를 정의하며, 상속한 서브클래스에서 구체적인 상태방정식 메서드를 구현한다.
- `computeState` 메서드는 온도와 밀도를 입력받아 헬름홀츠 함수를 계산하는 기본적인 인터페이스 역할을 합니다.
- `GetProps` 메서드는 주어진 온도와 밀도에 대해 해당 유체의 상세한 열역학적 물성치(상태, 압력, 건도, 엔탈피, 엔트로피, 비열, 음속 등)를 계산하여 구조체로 반환합니다. 내부적으로 `computeState`와 포화 물성치 계산 로직(`satDensity` 등)을 활용합니다.
- 2상 유동 및 열역학 시뮬레이션에서 공통 인터페이스를 통해 다양한 유체 모델을 통합하여 사용할 수 있다.

# Properties (Abstract, Constant)
- 각 유체 서브클래스에서 반드시 정의해야 하는 상수 속성들입니다.
  - `Tc`: 임계온도 [K]
  - `rhoc`: 임계밀도 [kg/m^3]
  - `R`: 특정 기체 상수 [J/(kg·K)]
  - `fluid_state`: 유체 극성 상태 (0=Non-Polar, 1=Polar)
  - `a1`, `a2`, `c0`, `c1`, `c2`: 이상 기체 헬름홀츠 에너지 계산 계수
  - `v`, `u`: Einstein Cp 모델 계수 벡터 (1×5)
  - `n`: 잔류 헬름홀츠 에너지 계산 계수 벡터 (1×12)

# Methods

## computeState
- 온도(`T`)와 밀도(`rho`)를 입력받아 해당 상태에서의 헬름홀츠 에너지 및 관련 파생 변수들을 계산합니다.
- 내부적으로 `HelmholtzEOS` 함수/클래스를 호출하여 계산을 수행합니다.

```MATLAB
function Helm = computeState(obj, T, rho)
	assert(T > 0 && rho > 0, 'T and rho must be positive.');
	Helm = HelmholtzEOS(obj, T, rho);
end
```

## GetProps
- 주어진 온도(`T`)와 밀도(`rho`)에서 유체의 전반적인 열역학적 상태와 물성치를 계산하여 `Props` 구조체로 반환합니다.
- **Input**: `obj` (FluidEOS 객체), `T` (온도, K), `rho` (밀도, kg/m³)
- **System**:
  1.  `obj.satDensity(T)`를 호출하여 해당 온도의 포화 액체 밀도(`rho_l`)와 포화 증기 밀도(`rho_v`)를 얻습니다.
  2.  입력된 밀도(`rho`)와 포화 밀도들을 비교하여 현재 상태(액체, 기체, 포화)를 판별합니다.
  3.  각 상태에 따라 필요한 헬름홀츠 상태 계산(`obj.computeState`)을 수행합니다.
      - 액체 (`rho >= rho_l`): 해당 밀도에서 계산.
      - 기체 (`rho <= rho_v`): 해당 밀도에서 계산.
      - 포화 (`rho_v < rho < rho_l`): `rho_l`과 `rho_v`에서 각각 계산.
  4.  건도($X$), 압력($P$), 각 상 및 혼합물의 내부에너지($u$), 엔트로피($s$), 엔탈피($h$), 비열($c_p$, $c_v$), 음속($c$) 등을 계산합니다.
      - 건도 계산 (포화 상태): 
        $$ X = \frac{\rho_v (\rho_l - \rho)}{\rho (\rho_l - \rho_v)} $$
      - 음속 계산 (포화 상태, Wood 식):
        $$ \frac{1}{\rho c^2} = \frac{\alpha}{\rho_v c_v^2} + \frac{1 - \alpha}{\rho_l c_l^2}, \quad \text{where } \alpha = \frac{X/\rho_v}{X/\rho_v + (1-X)/\rho_l} $$
- **Output (`Props` 구조체 필드)**:
  - `state`: 상태 (-1: 오류, 0: 액체, 1: 포화, 2: 기체)
  - `P`, `T`, `X`, `rho`: 압력, 온도, 건도, 밀도
  - `u`, `s`, `h`, `cp`, `cv`, `c`: 혼합물 내부에너지, 엔트로피, 엔탈피, 정압비열, 정적비열, 음속
  - `rho_v`, `u_v`, `s_v`, `h_v`, `cp_v`, `cv_v`, `c_v`: 증기상 물성치
  - `rho_l`, `u_l`, `s_l`, `h_l`, `cp_l`, `cv_l`, `c_l`: 액체상 물성치

# 전체 코드
```MATLAB
classdef (Abstract) FluidEOS
	properties (Abstract, Constant)
		%--- 임계 및 유체 상수 ---
		Tc % 임계온도 [K]
		rhoc % 임계밀도 [kg/m^3]
		R % 기체 상수 [J/(kg·K)]
		fluid_state % 0=Non-Polar, 1=Polar
		
		%--- 이상 기체 헬름홀츠 계수 ---
		a1 % 이상 기체 헬름홀츠 a1
		a2 % 이상 기체 헬름홀츠 a2
		c0 % 이상 기체 헬름홀츠 c0
		c1 % 이상 기체 헬름홀츠 c1
		c2 % 이상 기체 헬름홀츠 c2
		v % Einstein Cp 모델 벡터 (1×5)
		u % Einstein Cp 모델 벡터 (1×5)
		
		%--- 잔류 헬름홀츠 계수 벡터 (1×12) ---
		n
	end
	
	methods
		function Helm = computeState(obj, T, rho)
			assert(T > 0 && rho > 0, 'T and rho must be positive.');
			Helm = HelmholtzEOS(obj, T, rho);
		end
		
		function Props = GetProps(obj, T, rho, state_input)
            % Handle optional state_input argument
            if nargin < 4
                state_input = NaN;
            end

            % Initialize all Props fields to NaN
            Props.state = -1; Props.P = NaN; Props.T = NaN; Props.X = NaN;
            Props.rho = NaN; Props.u = NaN; Props.s = NaN; Props.h = NaN;
            Props.cp = NaN; Props.cv = NaN; Props.c = NaN;
            Props.rho_v = NaN; Props.u_v = NaN; Props.s_v = NaN; Props.h_v = NaN;
            Props.cp_v = NaN; Props.cv_v = NaN; Props.c_v = NaN;
            Props.rho_l = NaN; Props.u_l = NaN; Props.s_l = NaN; Props.h_l = NaN;
            Props.cp_l = NaN; Props.cv_l = NaN; Props.c_l = NaN;

            % Output T is always the input T
            Props.T = T;

            % Saturation densities
            [rho_l_sat, rho_v_sat] = obj.satDensity(T);

            % System Variables (will be populated in conditionals)
            % These are for internal calculation within this function
            X_calc = NaN; P_calc = NaN; state_calc = -1;
            u_calc = NaN; s_calc = NaN; h_calc = NaN; cp_calc = NaN; cv_calc = NaN; c_calc = NaN;
            u_l_calc = NaN; s_l_calc = NaN; h_l_calc = NaN; cp_l_calc = NaN; cv_l_calc = NaN; c_l_calc = NaN;
            u_v_calc = NaN; s_v_calc = NaN; h_v_calc = NaN; cp_v_calc = NaN; cv_v_calc = NaN; c_v_calc = NaN;
            rho_l_out_calc = NaN; rho_v_out_calc = NaN;
            rho_mixture_final = rho; % Default to input rho, may be overwritten for saturated case

            %% Phase Determination and Calculation
            if rho < 0 || T < 0 || imag(rho) % Check for invalid T, rho first
                state_calc = -1;
                warning('Props:InvalidInputTRho', 'Invalid T (%.2f K) or rho (%.2f kg/m^3) input.', T, rho);
                % All props remain NaN as initialized, rho_mixture_final remains input rho (but will be NaN if rho is invalid)

            % Liquid state (forced by state_input or determined by density)
            elseif (~isnan(state_input) && state_input == 0) || (isnan(state_input) && rho >= rho_l_sat)
                state_calc = 0;
                Helm = obj.computeState(T, rho); X_calc = 0; P_calc = Helm.P;
                rho_l_out_calc = rho; rho_v_out_calc = 0; % Vapor part is zero
                u_v_calc = 0; s_v_calc = 0; h_v_calc = 0; cp_v_calc = 0; cv_v_calc = 0; c_v_calc = 0;
                u_l_calc = Helm.u; s_l_calc = Helm.s; h_l_calc = Helm.h; cp_l_calc = Helm.cp; cv_l_calc = Helm.cv; c_l_calc = Helm.c;
                s_calc = s_l_calc; u_calc = u_l_calc; h_calc = h_l_calc; cp_calc = cp_l_calc; cv_calc = cv_l_calc; c_calc = c_l_calc;
                rho_mixture_final = rho;

            % Vapor state (forced by state_input or determined by density)
            elseif (~isnan(state_input) && state_input == 2) || (isnan(state_input) && rho <= rho_v_sat)
                state_calc = 2;
                Helm = obj.computeState(T, rho); X_calc = 1; P_calc = Helm.P;
                rho_l_out_calc = 0; rho_v_out_calc = rho; % Liquid part is zero
                u_l_calc = 0; s_l_calc = 0; h_l_calc = 0; cp_l_calc = 0; cv_l_calc = 0; c_l_calc = 0;
                u_v_calc = Helm.u; s_v_calc = Helm.s; h_v_calc = Helm.h; cp_v_calc = Helm.cp; cv_v_calc = Helm.cv; c_v_calc = Helm.c;
                s_calc = s_v_calc; u_calc = u_v_calc; h_calc = h_v_calc; cp_calc = cp_v_calc; cv_calc = cv_v_calc; c_calc = c_v_calc;
                rho_mixture_final = rho;

            % Saturated state (forced by state_input or determined by density)
            elseif (~isnan(state_input) && state_input == 1) || (isnan(state_input) && rho_v_sat < rho && rho < rho_l_sat)
                state_calc = 1;
                Helm_l = obj.computeState(T, rho_l_sat);
                Helm_v = obj.computeState(T, rho_v_sat);
                rho_l_out_calc = rho_l_sat; rho_v_out_calc = rho_v_sat;
                
                P_calc = Helm_v.P; % Saturation pressure (Helm_l.P should be the same)
                u_l_calc = Helm_l.u; s_l_calc = Helm_l.s; h_l_calc = Helm_l.h; cp_l_calc = Helm_l.cp; cv_l_calc = Helm_l.cv; c_l_calc = Helm_l.c;
                u_v_calc = Helm_v.u; s_v_calc = Helm_v.s; h_v_calc = Helm_v.h; cp_v_calc = Helm_v.cp; cv_v_calc = Helm_v.cv; c_v_calc = Helm_v.c;

                % Calculate Quality (X) using the original input 'rho' for this GetProps call
                % This logic is preserved from the user's provided FluidEOS.m
                current_call_rho_for_X = rho; 
                if rho_l_sat == rho_v_sat % Avoid division by zero (e.g. critical point)
                    X_intermediate_calc = NaN; 
                    warning_id_suffix = ifthenelse(~isnan(state_input) && state_input == 1, 'ForcedSatXUndefAtCrit', 'DensitySatXUndefAtCrit');
                    warning(['Props:' warning_id_suffix], 'X undefined (rho_l_sat=rho_v_sat) at T=%.2f K. Input rho=%.2f.', T, current_call_rho_for_X);
                else
                    X_intermediate_calc = (1/current_call_rho_for_X - 1/rho_l_sat) / (1/rho_v_sat - 1/rho_l_sat);
                end
                X_calc = X_intermediate_calc;

                % Clamp X to [0, 1] and issue warnings
                if isnan(X_calc) || X_calc > 1
                    if ~isnan(X_calc) && X_calc > 1
                        warning_id_suffix = ifthenelse(~isnan(state_input) && state_input == 1, 'ForcedSatXClampedToOne', 'DensitySatXClampedToOne');
                        warning(['Props:' warning_id_suffix], 'X=%.4f > 1, clamped to 1. T=%.2f, rho_in=%.2f', X_calc, T, current_call_rho_for_X);
                    end
                    X_calc = 1;
                elseif X_calc < 0
                    warning_id_suffix = ifthenelse(~isnan(state_input) && state_input == 1, 'ForcedSatXClampedToZero', 'DensitySatXClampedToZero');
                    warning(['Props:' warning_id_suffix], 'X=%.4f < 0, clamped to 0. T=%.2f, rho_in=%.2f', X_calc, T, current_call_rho_for_X);
                    X_calc = 0;
                end
                
                % Recalculate overall mixture density 'rho_mixture_final' based on (potentially clamped) X_calc.
                if X_calc == 1
                    rho_mixture_final = rho_v_sat;
                elseif X_calc == 0
                    rho_mixture_final = rho_l_sat;
                else
                    if rho_l_sat == rho_v_sat 
                         rho_mixture_final = rho_l_sat; % or rho_v_sat
                    else
                         rho_mixture_final = 1 / (X_calc / rho_v_sat + (1-X_calc) / rho_l_sat);
                    end
                end

                s_calc = s_v_calc*X_calc + s_l_calc*(1-X_calc); 
                u_calc = u_v_calc*X_calc + u_l_calc*(1-X_calc); 
                h_calc = h_v_calc*X_calc + h_l_calc*(1-X_calc);
                cp_calc = cp_v_calc*X_calc + cp_l_calc*(1-X_calc); 
                cv_calc = cv_v_calc*X_calc + cv_l_calc*(1-X_calc);
                
                % Sound speed (Wood's equation)
                term_v = X_calc./rho_v_sat; term_l = (1-X_calc)./rho_l_sat;
                if (abs(term_v + term_l) < eps) % Avoid division by zero if sum is tiny
                    alpha = NaN; c_calc = NaN;
                    warning_id_suffix = ifthenelse(~isnan(state_input) && state_input == 1, 'ForcedSatAlphaUndef', 'DensitySatAlphaUndef');
                    warning(['Props:' warning_id_suffix], 'Cannot calculate alpha for sound speed. T=%.2f K, X=%.4f', T, X_calc);
                else
            alpha = term_v ./ (term_v + term_l);
                    if rho_v_sat <= 0 || c_v_calc <= 0 || isnan(c_v_calc) || isnan(c_l_calc) || rho_l_sat <= 0 || c_l_calc <= 0 || isnan(c_l_calc) % c_v_calc from mixture, c_l/c_v from phases
                        c_calc = NaN;
                        warning_id_suffix = ifthenelse(~isnan(state_input) && state_input == 1, 'ForcedSatSoundSpeedErrorInPhase', 'DensitySatSoundSpeedErrorInPhase');
                        warning(['Props:' warning_id_suffix], 'Cannot calculate sound speed due to invalid phase props. T=%.2f K, X=%.4f', T,X_calc);
                    else
                        % Ensure phase-specific sound speeds c_v_calc (vapor) and c_l_calc (liquid) are valid
                        sound_speed_denom_v = rho_v_sat.*c_v_calc.^2; % Using Helm_v.c (c_v_calc for vapor phase)
                        sound_speed_denom_l = rho_l_sat.*c_l_calc.^2; % Using Helm_l.c (c_l_calc for liquid phase)
                        if sound_speed_denom_v == 0 || sound_speed_denom_l == 0 % Avoid division by zero
                             c_calc = NaN;
                             warning(['Props:' warning_id_suffix], 'Cannot calculate sound speed due to zero denominator from phase sound speeds. T=%.2f K, X=%.4f',T,X_calc);
                        else
                            c_calc = sqrt( 1 ./ ( alpha./sound_speed_denom_v + (1-alpha)./sound_speed_denom_l ) );
                        end
                    end
                end

            % Handle invalid state_input value if it wasn't one of 0, 1, 2 and no density condition was met
            elseif ~isnan(state_input)
                state_calc = -1; % Error state
                warning('Props:InvalidStateInputValue', 'state_input=%.1f is invalid. Setting to error state.', state_input);
                 % Props remain NaN, rho_mixture_final is original (potentially invalid) rho
            
            % Fallback for any other unhandled condition (e.g. rho == rho_l_sat == rho_v_sat at critical point, if not caught by X calc)
            else 
                state_calc = -1; % Safety net
                warning('Props:UnhandledCondition', 'An unhandled condition was met for T=%.2f, rho=%.2f, state_input=%.1f. Setting to error state.', T, rho, state_input);
                 % Props remain NaN, rho_mixture_final is original (potentially invalid) rho
            end

            %% Output Assignment
            Props.state = state_calc;
            Props.P = P_calc;
            Props.X = X_calc;
            Props.rho = rho_mixture_final; %This is the input rho for single phase, or X-recalculated rho for sat.
            Props.u = u_calc; Props.s = s_calc; Props.h = h_calc;
            Props.cp = cp_calc; Props.cv = cv_calc; Props.c = c_calc;

            Props.rho_v = rho_v_out_calc; Props.u_v = u_v_calc; Props.s_v = s_v_calc; Props.h_v = h_v_calc;
            Props.cp_v = cp_v_calc; Props.cv_v = cv_v_calc; Props.c_v = ifthenelse(state_calc == 2, c_calc, c_v_calc); % Props.c_v is sound speed for pure vapor phase

            Props.rho_l = rho_l_out_calc; Props.u_l = u_l_calc; Props.s_l = s_l_calc; Props.h_l = h_l_calc;
            Props.cp_l = cp_l_calc; Props.cv_l = cv_l_calc; Props.c_l = ifthenelse(state_calc == 0, c_calc, c_l_calc); % Props.c_l is sound speed for pure liquid phase
        end
    end
end

% Helper function for conditional assignment (mimics ternary operator)
function result = ifthenelse(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end