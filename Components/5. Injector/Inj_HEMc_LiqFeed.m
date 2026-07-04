function [x] = Inj_HEMc_LiqFeed(x)
%Inj_HEMc_LiqFeed  2상 입구 HEM_c 인젝터 모델 - 액상 유출 (선택적 급기 라인 결합)
%   mdot = Cd * A * G_HEM(max(P2, r_choke*P1)),  G_HEM(Pe) = rho2*sqrt(2(h1-h2)), s2 = s1
%   - HEM(균질 평형)은 고전 2상 임계유동 모델(Starkman 1964/Moody 1965/Wallis 1969).
%     초크 캡(플럭스 최대점 수치 탐색)은 La Luna 2022 4.3절/2023 2.3절 방식
%     (포화액 상류의 임계 압력비 ~0.75-0.77).
%   - x.feed.mode == 1: Feed_Line(급기 라인)과 유량 이분법으로 결합.
%     상류 = 라인 출구의 2상 혼합 상태 (라인 플래싱 반영).
%     근거: 2026 수류시험 - 인젝터 단독 판정(2상 입구 HEM_c만 물리적 Cd에 근접) 및
%     결합 리허설(mdot +4~12%, P_inj RMSE ~0.2 bar, Cd~0.55).
%   - x.feed.mode == 0: 탱크 직결 - 상류 = 탱크 포화액 (HEM_c(liq)).
%   - 고속화: CoolProp 선택 시 상태/플럭스를 N2O_SatTable(포화선 보간) 지렛대로
%     계산 (핫루프 py 호출 없음) + 직전 스텝 유량 워밍 스타트 이분법.
%   선행 조건 없음 (InjState_* 결과에 의존하지 않고 자체적으로 상류 상태를 정의).

%% Input
fluid = x.fluid;
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_HEMc_LiqFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_HEMc_LiqFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

h1 = x.tank.h_l;      % 상류 비엔탈피 (라인 단열 -> 보존)
T1 = x.tank.T;        % 등엔트로피 솔버 초기 추정값 (인하우스 경로)
rho1_guess = x.tank.rho_l;
A_inj = x.inj.A;
Cd_inj = x.inj.Cd;
use_feed = isfield(x, 'feed') && isfield(x.feed, 'mode') && x.feed.mode == 1;
use_table = ismethod(fluid, 'GetPropsPH'); % CoolProp: 포화 테이블 지렛대 사용

%% System
persistent P1_prev m_prev % 직전 스텝의 라인 출구 압력/유량 (워밍 스타트)
mdot_inj = 0;
P1 = x.tank.P;
x1_in = 0;                 % 인젝터 입구 건도 (직결 시 포화액 = 0)
r_choke = NaN;
hem_choked = false;
pressure_ratio = NaN;
feed_out = [];

if x.tank.P > P2

    if use_feed
        % ============ 급기 라인 결합: 유량 이분법 ============
        % 초크 압력비: 직전 스텝 출구 압력 추정점에서 계산 (캐시 포함, P1에 둔감)
        if isempty(P1_prev) || ~isfinite(P1_prev)
            P1_est = 0.6 * x.tank.P;
        else
            P1_est = min(P1_prev, 0.98 * x.tank.P);
        end
        s1_est = lever_entropy(fluid, P1_est, h1, use_table);
        if isfinite(s1_est)
            r_choke = FindChokeRatio(fluid, P1_est, s1_est, h1, T1, rho1_guess, use_table);
        end
        if ~isfinite(r_choke)
            r_choke = 0.75; % 포화액 대표값 폴백 (La Luna 2023)
        end

        % 이분법 구간: 직전 스텝 유량 +-30% 워밍 스타트, 실패 시 전 구간
        warm = ~isempty(m_prev) && isfinite(m_prev) && m_prev > 1e-3;
        if warm && hemc_resid(0.7 * m_prev) > 0 && hemc_resid(1.3 * m_prev) < 0
            lo = 0.7 * m_prev; hi = 1.3 * m_prev;
        else
            lo = 1e-4; hi = est_hi();
        end

        if hemc_resid(lo) <= 0
            mdot_inj = 0; % 최소 유량조차 라인/인젝터를 통과 불가
        else
            for it = 1:12
                mid = 0.5 * (lo + hi);
                if hemc_resid(mid) > 0
                    lo = mid;
                else
                    hi = mid;
                end
            end
            mdot_inj = 0.5 * (lo + hi);
            feed_out = Feed_Line(x, mdot_inj);
            if feed_out.ok
                P1 = feed_out.P_out;
                x1_in = feed_out.x_out;
                P1_prev = P1;
                m_prev = mdot_inj;
                pressure_ratio = P2 / P1;
                hem_choked = pressure_ratio < r_choke;
            else
                warning('Inj_HEMc_LiqFeed:FeedLineFail', 'Converged mdot (%.4f kg/s) failed final Feed_Line evaluation.', mdot_inj);
                mdot_inj = 0;
            end
        end

    else
        % ============ 탱크 직결: 상류 = 탱크 포화액 ============
        s1 = x.tank.s_l;
        r_choke = FindChokeRatio(fluid, P1, s1, h1, T1, rho1_guess, use_table);
        pressure_ratio = P2 / P1;
        Pe = P2;
        if isfinite(r_choke) && pressure_ratio < r_choke
            Pe = r_choke * P1; % 초크 캡
            hem_choked = true;
        elseif ~isfinite(r_choke)
            warning('Inj_HEMc_LiqFeed:ChokeSearchFail', 'HEM choke-point search failed. Using downstream (P2) state without cap.');
        end
        [G, okG] = hem_flux_at(fluid, Pe, s1, h1, T1, rho1_guess, use_table);
        if okG
            mdot_inj = Cd_inj * A_inj * G;
        else
            warning('Inj_HEMc_LiqFeed:InvalidState', 'Isentropic flux evaluation failed. Setting mdot_inj = 0.');
            mdot_inj = 0;
        end
    end

end % x.tank.P > P2

%% Output
x.inj.mdot = mdot_inj;
x.inj.mdot_HEM = mdot_inj;        % HEM 단독 모델: HEM 성분 = 전체 유량
x.inj.ratio_Pcr_HEM = r_choke;    % HEM 초크점 압력비
x.inj.ratio_P = pressure_ratio;   % P2 / P1 (P1 = 인젝터 입구 압력)
x.inj.choked = hem_choked;
x.inj.x1_in = x1_in;              % 인젝터 입구 건도 (라인 플래싱 진단)
if use_feed
    if ~isempty(feed_out) && feed_out.ok
        x.feed.P_out = feed_out.P_out;
        x.feed.x_out = feed_out.x_out;
        x.feed.dP_line = feed_out.dP_line;
    else
        x.feed.P_out = NaN;
        x.feed.x_out = NaN;
        x.feed.dP_line = NaN;
    end
end

    function r = hemc_resid(m)
        %hemc_resid 결합 잔차: 인젝터 요구 유량(라인 출구 상류 기준) - 가정 유량
        fo = Feed_Line(x, m);
        if ~fo.ok
            r = -1; % 라인 통과 불가 -> 유량 과대
            return;
        end
        s1c = lever_entropy(fluid, fo.P_out, h1, use_table);
        if ~isfinite(s1c)
            r = -1;
            return;
        end
        Pe_c = max(P2, r_choke * fo.P_out); % HEM 초크 캡
        [Gc, okc] = hem_flux_at(fluid, Pe_c, s1c, h1, T1, rho1_guess, use_table);
        if okc
            r = Cd_inj * A_inj * Gc - m;
        else
            r = -1;
        end
    end

    function hi_out = est_hi()
        %est_hi 이분법 상한: 라인 손실 없이 탱크 상류로 계산한 유량
        [G0, ok0] = hem_flux_at(fluid, max(P2, r_choke * x.tank.P), x.tank.s_l, h1, T1, rho1_guess, use_table);
        if ok0
            hi_out = max(1.1 * Cd_inj * A_inj * G0, 2e-4);
        else
            hi_out = 1.0;
        end
    end

end

function s1 = lever_entropy(fluid, P, h, use_table)
%lever_entropy (P,h) 상태의 비엔트로피 (2상: 포화 테이블 지렛대, 폴백: GetPropsPH)
if use_table
    s = N2O_SatTable(P);
    if s.ok
        X = (h - s.hl) / max(s.hv - s.hl, eps);
        X = min(max(X, 0), 1);
        s1 = s.sl + X * (s.sv - s.sl);
        return;
    end
end
if ismethod(fluid, 'GetPropsPH')
    Pr = fluid.GetPropsPH(P, h);
    if Pr.state ~= -1 && isfinite(Pr.s)
        s1 = Pr.s;
    else
        s1 = NaN;
    end
else
    s1 = NaN; % 인하우스 직결 경로에서는 호출되지 않음 (s1 = x.tank.s_l 사용)
end
end

function [G, ok] = hem_flux_at(fluid, Pe, s1, h1, guessT, guessRho, use_table)
%hem_flux_at 등엔트로피 팽창 질량 플럭스 G(Pe) = rho2*sqrt(2(h1-h2)), s2 = s1
if use_table
    s = N2O_SatTable(Pe);
    if s.ok
        X2 = (s1 - s.sl) / max(s.sv - s.sl, eps);
        if X2 >= -0.001 && X2 <= 1.001 % 2상 구간 (지렛대 유효)
            X2 = min(max(X2, 0), 1);
            h2 = s.hl + X2 * (s.hv - s.hl);
            rho2 = 1 / (X2 / s.rhov + (1 - X2) / s.rhol);
            if h1 > h2
                G = rho2 * sqrt(2 * (h1 - h2)); ok = true;
            else
                G = 0; ok = false;
            end
            return;
        end
    end
end
st = SolveIsentropicStateH(fluid, Pe, s1, guessT, guessRho);
if st.valid && h1 > st.h
    G = st.rho * sqrt(2 * (h1 - st.h)); ok = true;
else
    G = 0; ok = false;
end
end

function r_best = FindChokeRatio(fluid, P1, s1, h1, guessT, guessRho, use_table)
%FindChokeRatio HEM 질량 플럭스 최대점(2상 초크점) 압력비 탐색 (황금분할 + 캐시)
persistent cP1 cs1 cr
if use_table || ismethod(fluid, 'GetPropsPS')
    tol_cache = 0.001;
else
    tol_cache = 0.005;
end
if ~isempty(cP1) && ~isempty(cr) && isfinite(cr) && ...
        abs(P1 - cP1) <= tol_cache * cP1 && abs(s1 - cs1) <= tol_cache * abs(cs1)
    r_best = cr;
    return;
end

phi = (sqrt(5) - 1) / 2;
if ~isempty(cr) && isfinite(cr)
    a = max(0.05, cr - 0.15); b = min(0.995, cr + 0.15); n_iter = 12;
else
    a = 0.30; b = 0.995; n_iter = 16;
end

x1 = b - phi * (b - a); x2 = a + phi * (b - a);
f1 = flx(x1); f2 = flx(x2);
for it = 1:n_iter
    if f1 >= f2
        b = x2; x2 = x1; f2 = f1;
        x1 = b - phi * (b - a); f1 = flx(x1);
    else
        a = x1; x1 = x2; f1 = f2;
        x2 = a + phi * (b - a); f2 = flx(x2);
    end
end
if f1 >= f2, r_best = x1; f_best = f1; else, r_best = x2; f_best = f2; end

if ~isfinite(f_best) || f_best <= 0
    r_best = NaN;
else
    cP1 = P1; cs1 = s1; cr = r_best; % 유효한 결과만 캐시
end

    function G = flx(r)
        [g, okf] = hem_flux_at(fluid, r * P1, s1, h1, guessT, guessRho, use_table);
        if okf, G = g; else, G = -Inf; end
    end
end

function st = SolveIsentropicStateH(fluid, P_target, s_target, guessT, guessRho)
%SolveIsentropicStateH  목표 압력까지의 등엔트로피 상태 계산 + 해 검증 (폴백 경로)
%   CoolProp이면 내장 P-s 플래시, 인하우스면 무차원 잔차 lsqnonlin + 가짜 근 검증.
if ismethod(fluid, 'GetPropsPS')
    Props = fluid.GetPropsPS(P_target, s_target);
    st.T = Props.T; st.rho = Props.rho; st.h = Props.h; st.X = Props.X;
    st.rho_l = Props.rho_l; st.rho_v = Props.rho_v;
    st.valid = Props.state ~= -1 && isfinite(Props.rho) && Props.rho > 0 && isfinite(Props.h);
    return;
end

lb = [183, 2.7];
ub = [309, 1236];
pFunc = @(v) [ (getfield(fluid.GetProps(v(1), v(2)), 'P') - P_target) / max(abs(P_target), 1);
               (getfield(fluid.GetProps(v(1), v(2)), 's') - s_target) / max(abs(s_target), 1) ];
v = lsqnonlin(pFunc, [guessT, guessRho], lb, ub, optimset('Display', 'off', 'TolFun', 1e-12));
Props = fluid.GetProps(v(1), v(2), 1);
st.T = v(1);
st.rho = Props.rho;
st.h = Props.h;
st.X = Props.X;
st.rho_l = Props.rho_l;
st.rho_v = Props.rho_v;
P_err = abs(Props.P - P_target) / max(abs(P_target), 1);
s_err = abs(Props.s - s_target) / max(abs(s_target), 1);
on_bound = (v(2) >= 0.98 * ub(2)) || (v(1) <= lb(1) + 0.5) || (v(1) >= ub(1) - 0.5);
st.valid = isfinite(Props.rho) && isfinite(Props.h) && P_err < 5e-3 && s_err < 5e-3 && ~on_bound;
end
