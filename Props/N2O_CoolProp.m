classdef N2O_CoolProp
%N2O_CoolProp  CoolProp 기반 N2O 물성 모델 (인하우스 N2O + HelmholtzEOS 대체)
%   - 기존 FluidEOS 인터페이스(GetProps, satDensity, CEACard)와 동일한 출력 구조를
%     제공하므로 u.tank.prop_model = "CoolProp" 선택만으로 전체 시뮬레이션에 반영된다.
%   - 상태 솔버용 직접 플래시 GetPropsPS(P,s), GetPropsDH(rho,h)를 추가로 제공한다.
%     Tank_*Feed / InjState_* / FML 초크 탐색은 이 메서드 존재 여부(ismethod)로
%     lsqnonlin 대신 내장 플래시를 사용한다 (가짜 근 원천 차단).
%   - 요구 사항: MATLAB pyenv에 CoolProp이 설치된 파이썬 연결 (CEA와 동일 경로).
%   - 주의: CoolProp의 N2O도 인하우스와 같은 Lemmon-Span(2006) 상관식이지만,
%     h/s의 기준상태(영점)가 다르다. 한 런 안에서는 일관되므로 물리 결과(P, T,
%     rho, 유량, 추력)는 동일 기준으로 비교 가능하나, h/s 절대값 플롯은 모델 간
%     상수 오프셋이 있다.
%   - 플래시 실패(영역 밖 등) 시 예외 대신 state = -1 (전 필드 NaN)을 반환한다.
%     호출측은 state == -1 또는 isfinite()로 유효성을 판단할 것.

    properties (Constant)
        % 임계 상수 (Lemmon-Span 2006; 인하우스 N2O.m과 동일 표기)
        Tc = 309.52;             % K
        rhoc = 452.011456;       % kg/m^3
        Ru = 8.31446261815324;   % J/(mol K)
        M = 44.0128e-3;          % kg/mol
        R = N2O_CoolProp.Ru / N2O_CoolProp.M; % J/(kg K)

        fluid_name = 'NitrousOxide'; % CoolProp 유체 이름

        % CEA Card String for N2O as oxidizer (N2O.m과 동일)
        CEACard = ['oxid N2O N 2.0 O 1.0 wt%=100.0', newline, ...
                   'h,cal = 19467.0 t(k) = 298.15']; % h: cal/mol
    end

    methods
        function [rhoL, rhoV] = satDensity(obj, Tq)
            %satDensity 온도 Tq에서의 포화 액체/증기 밀도 (CoolProp 포화 계산)
            rhoL = obj.cpsi('D', 'T', Tq, 'Q', 0);
            rhoV = obj.cpsi('D', 'T', Tq, 'Q', 1);
        end

        function Props = GetProps(obj, T, rho, state_input)
            %GetProps (T, rho[, 강제상]) 상태의 물성 - FluidEOS.GetProps와 동일 구조
            %   state_input: 0 액체 강제, 1 포화 강제, 2 기체 강제, 생략/NaN 자동
            if nargin < 4
                state_input = NaN;
            end
            Props = N2O_CoolProp.emptyProps();
            Props.T = T;

            if ~isfinite(T) || ~isfinite(rho) || T <= 0 || rho <= 0
                warning('N2O_CoolProp:InvalidInputTRho', 'Invalid T (%.2f K) or rho (%.2f kg/m^3) input.', T, rho);
                return;
            end

            % 포화 밀도 (초임계 등으로 조회 불가하면 단상 T-D 처리)
            try
                [rho_l_sat, rho_v_sat] = obj.satDensity(T);
            catch
                rho_l_sat = NaN; rho_v_sat = NaN;
            end
            if ~isfinite(rho_l_sat) || ~isfinite(rho_v_sat)
                try
                    st = obj.queryState('T', T, 'D', rho);
                    Props = N2O_CoolProp.singleProps(st, rho >= obj.rhoc);
                    Props.rho = rho;
                catch ME
                    warning('N2O_CoolProp:TDFlashFail', 'T-D 상태 계산 실패 (T=%.2f K, rho=%.2f): %s', T, rho, ME.message);
                end
                return;
            end

            forced_liq = ~isnan(state_input) && state_input == 0;
            forced_vap = ~isnan(state_input) && state_input == 2;
            forced_sat = ~isnan(state_input) && state_input == 1;

            try
                if forced_liq || (isnan(state_input) && rho >= rho_l_sat)
                    % --- 액체 (강제 또는 밀도 판정) ---
                    if rho <= rho_l_sat * 1.005
                        st = obj.queryState('T', T, 'Q', 0); % 포화 경계: Q=0 상태로 견고하게
                    else
                        st = obj.queryState('T', T, 'D', rho); % 압축 액체
                    end
                    Props = N2O_CoolProp.singleProps(st, true);
                    Props.T = T; Props.rho = rho;
                elseif forced_vap || (isnan(state_input) && rho <= rho_v_sat)
                    % --- 기체 (강제 또는 밀도 판정) ---
                    if rho >= rho_v_sat * 0.995
                        st = obj.queryState('T', T, 'Q', 1); % 포화 경계: Q=1 상태로 견고하게
                    else
                        st = obj.queryState('T', T, 'D', rho); % 과열 증기
                    end
                    Props = N2O_CoolProp.singleProps(st, false);
                    Props.T = T; Props.rho = rho;
                else
                    % --- 포화 혼합 (강제 1 또는 rho가 돔 내부) ---
                    if rho_l_sat == rho_v_sat
                        X = NaN; % 임계점
                    else
                        X = (1/rho - 1/rho_l_sat) / (1/rho_v_sat - 1/rho_l_sat);
                    end
                    X = min(max(X, 0), 1); % clamp (FluidEOS와 동일 방침)
                    if forced_sat && ~isfinite(X)
                        X = 1;
                    end
                    Props = obj.mixtureProps(T, X);
                end
            catch ME
                warning('N2O_CoolProp:GetPropsFail', 'GetProps 실패 (T=%.2f K, rho=%.2f, state=%g): %s', T, rho, state_input, ME.message);
                Props = N2O_CoolProp.emptyProps();
                Props.T = T;
            end
        end

        function Props = GetPropsPS(obj, P, s)
            %GetPropsPS 압력-엔트로피 직접 플래시 (등엔트로피 팽창 상태 계산용)
            %   실패 시 state = -1 반환 (예외 없음; 초크점 탐색이 영역 밖을 탐침할 수 있음)
            Props = N2O_CoolProp.emptyProps();
            try
                T = obj.cpsi('T', 'P', P, 'S', s);
                Q = obj.cpsi('Q', 'P', P, 'S', s);
                if Q >= 0 && Q <= 1
                    Props = obj.mixtureProps(T, Q);
                    Props.P = P; % 플래시 입력 압력을 그대로 유지
                else
                    st = obj.queryState('P', P, 'S', s);
                    Props = N2O_CoolProp.singleProps(st, st.rho >= obj.rhoc);
                end
            catch
                % 영역 밖/수렴 실패: state = -1 유지 (호출측에서 유효성 검사)
            end
        end

        function Props = GetPropsDH(obj, rho, h)
            %GetPropsDH 밀도-엔탈피 직접 플래시 (탱크 엔탈피 알고리즘용)
            %   실패 시 state = -1 반환 (예외 없음; 호출측에서 lsqnonlin 폴백 가능)
            Props = N2O_CoolProp.emptyProps();
            try
                T = obj.cpsi('T', 'D', rho, 'H', h);
                Q = obj.cpsi('Q', 'D', rho, 'H', h);
                if Q >= 0 && Q <= 1
                    Props = obj.mixtureProps(T, Q);
                    Props.rho = rho; % 입력 밀도 유지 (질량 보존과 일관)
                else
                    st = obj.queryState('D', rho, 'H', h);
                    Props = N2O_CoolProp.singleProps(st, rho >= obj.rhoc);
                    Props.rho = rho;
                end
            catch
                % state = -1 유지
            end
        end

        function Props = GetPropsPH(obj, P, h)
            %GetPropsPH 압력-엔탈피 상태 계산 (공급 라인 행진: 단열 라인에서 h 보존)
            %   2상 구간은 포화 엔탈피 지렛대로 건도를 직접 결정하여 CoolProp P-H
            %   플래시의 포화 경계 수렴 실패를 우회한다 (탱크 출구 = 정확히 포화액
            %   경계라 직접 플래시는 실패할 수 있음). 실패 시 state = -1 반환.
            Props = N2O_CoolProp.emptyProps();
            % 포화 기준값 (아임계에서 항상 견고)
            try
                Tsat = obj.cpsi('T', 'P', P, 'Q', 0);
                hl = obj.cpsi('H', 'P', P, 'Q', 0);
                hv = obj.cpsi('H', 'P', P, 'Q', 1);
            catch
                Tsat = NaN; hl = NaN; hv = NaN; % 초임계 등 -> 단상 경로
            end
            try
                if isfinite(Tsat) && h >= hl && h <= hv
                    % 2상: 건도 = 엔탈피 지렛대 (P-H 플래시 불필요)
                    X = (h - hl) / max(hv - hl, eps);
                    Props = obj.mixtureProps(Tsat, X);
                    Props.P = P;
                else
                    st = obj.queryState('P', P, 'H', h); % 단상 (과냉/과열)
                    Props = N2O_CoolProp.singleProps(st, st.rho >= obj.rhoc);
                end
            catch
                % 단상 플래시가 포화 경계 근처에서 실패한 경우: 경계 상태로 클램프
                try
                    if isfinite(Tsat) && h < hl
                        Props = obj.mixtureProps(Tsat, 0); % 포화액 경계 근사
                        Props.P = P;
                    elseif isfinite(Tsat) && h > hv
                        Props = obj.mixtureProps(Tsat, 1); % 포화증기 경계 근사
                        Props.P = P;
                    end
                catch
                    % state = -1 유지
                end
            end
        end
    end

    methods (Access = private)
        function v = cpsi(~, out, n1, v1, n2, v2)
            %cpsi CoolProp PropsSI 단일 호출 래퍼 (실패 시 예외 전파)
            v = double(py.CoolProp.CoolProp.PropsSI(out, n1, v1, n2, v2, 'NitrousOxide'));
        end

        function st = queryState(obj, n1, v1, n2, v2)
            %queryState 지정 입력쌍의 단상 상태 물성 일괄 조회
            st.P   = obj.cpsi('P', n1, v1, n2, v2);
            st.T   = obj.cpsi('T', n1, v1, n2, v2);
            st.rho = obj.cpsi('D', n1, v1, n2, v2);
            st.u   = obj.cpsi('U', n1, v1, n2, v2);
            st.s   = obj.cpsi('S', n1, v1, n2, v2);
            st.h   = obj.cpsi('H', n1, v1, n2, v2);
            st.cp  = obj.cpsi('C', n1, v1, n2, v2);
            st.cv  = obj.cpsi('O', n1, v1, n2, v2);
            st.c   = obj.cpsi('A', n1, v1, n2, v2);
        end

        function Props = mixtureProps(obj, T, X)
            %mixtureProps 포화 혼합 상태 구성 (FluidEOS 포화 분기와 동일 규약)
            stL = obj.queryState('T', T, 'Q', 0);
            stV = obj.queryState('T', T, 'Q', 1);

            Props = N2O_CoolProp.emptyProps();
            Props.state = 1;
            Props.T = T;
            Props.X = X;
            Props.P = stL.P; % 포화 압력

            % 상별 물성
            Props.rho_l = stL.rho; Props.u_l = stL.u; Props.s_l = stL.s; Props.h_l = stL.h;
            Props.cp_l = stL.cp; Props.cv_l = stL.cv; Props.c_l = stL.c;
            Props.rho_v = stV.rho; Props.u_v = stV.u; Props.s_v = stV.s; Props.h_v = stV.h;
            Props.cp_v = stV.cp; Props.cv_v = stV.cv; Props.c_v = stV.c;

            % 혼합 물성 (건도 가중 - FluidEOS와 동일)
            if X <= 0
                Props.rho = stL.rho;
            elseif X >= 1
                Props.rho = stV.rho;
            else
                Props.rho = 1 / (X / stV.rho + (1 - X) / stL.rho);
            end
            Props.u  = X * stV.u  + (1 - X) * stL.u;
            Props.s  = X * stV.s  + (1 - X) * stL.s;
            Props.h  = X * stV.h  + (1 - X) * stL.h;
            Props.cp = X * stV.cp + (1 - X) * stL.cp;
            Props.cv = X * stV.cv + (1 - X) * stL.cv;

            % 혼합 음속: Wood 형태 (FluidEOS의 기존 식을 그대로 재현)
            term_v = X / stV.rho; term_l = (1 - X) / stL.rho;
            if abs(term_v + term_l) < eps || stV.c <= 0 || stL.c <= 0
                Props.c = NaN;
            else
                alpha = term_v / (term_v + term_l);
                Props.c = sqrt(1 / (alpha / (stV.rho * stV.c^2) + (1 - alpha) / (stL.rho * stL.c^2)));
            end
        end
    end

    methods (Static, Access = private)
        function Props = emptyProps()
            %emptyProps 전 필드 NaN + state -1 (FluidEOS 초기화와 동일 필드 구성)
            Props = struct('state', -1, 'P', NaN, 'T', NaN, 'X', NaN, ...
                'rho', NaN, 'u', NaN, 's', NaN, 'h', NaN, 'cp', NaN, 'cv', NaN, 'c', NaN, ...
                'rho_v', NaN, 'u_v', NaN, 's_v', NaN, 'h_v', NaN, 'cp_v', NaN, 'cv_v', NaN, 'c_v', NaN, ...
                'rho_l', NaN, 'u_l', NaN, 's_l', NaN, 'h_l', NaN, 'cp_l', NaN, 'cv_l', NaN, 'c_l', NaN);
        end

        function Props = singleProps(st, is_liquid)
            %singleProps 단상 상태 구성 (FluidEOS 단상 분기와 동일 규약:
            %   해당 상 필드에 값, 반대 상 필드는 0)
            Props = N2O_CoolProp.emptyProps();
            Props.P = st.P; Props.T = st.T; Props.rho = st.rho;
            Props.u = st.u; Props.s = st.s; Props.h = st.h;
            Props.cp = st.cp; Props.cv = st.cv; Props.c = st.c;
            if is_liquid
                Props.state = 0; Props.X = 0;
                Props.rho_l = st.rho; Props.u_l = st.u; Props.s_l = st.s; Props.h_l = st.h;
                Props.cp_l = st.cp; Props.cv_l = st.cv; Props.c_l = st.c;
                Props.rho_v = 0; Props.u_v = 0; Props.s_v = 0; Props.h_v = 0;
                Props.cp_v = 0; Props.cv_v = 0; Props.c_v = 0;
            else
                Props.state = 2; Props.X = 1;
                Props.rho_v = st.rho; Props.u_v = st.u; Props.s_v = st.s; Props.h_v = st.h;
                Props.cp_v = st.cp; Props.cv_v = st.cv; Props.c_v = st.c;
                Props.rho_l = 0; Props.u_l = 0; Props.s_l = 0; Props.h_l = 0;
                Props.cp_l = 0; Props.cv_l = 0; Props.c_l = 0;
            end
        end
    end
end
