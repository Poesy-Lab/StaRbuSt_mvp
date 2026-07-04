function [x] = Inj_NHNE_VapFeed(x)
%Inj_NHNE_VapFeed  FML(Foletti-Magni-La Luna) 질량 유량 모델 - 증기상 유출
%   출처: La Luna et al., "A Two-Phase Mass Flow Rate Model for Nitrous
%   Oxide Based on Void Fraction", Aerospace 2022, 9(12), 828. (식 (23))
%   - 가중치 alpha2: 하류(P2) 등엔트로피 상태의 보이드율 (InjState_VapFeed 결과)
%   - HEM 항: 등엔트로피 팽창 경로 위 질량 플럭스의 최대점(초크점)에서 캡
%     (논문 4.3절의 수치 탐색 방식; SPC 임계비와는 별개의 기준)
%   선행 조건: InjState_VapFeed가 먼저 호출되어 하류 등엔트로피 상태가
%   x.inj.*에 준비되어 있어야 함.
%
%   급기 라인 결합 (x.feed.mode == 1, CoolProp 물성):
%   액체 소진 후에도 탱크 포화증기가 같은 라인을 지나므로, 라인 출구 상태
%   (Feed_Line 증기 행진: h = h_v 보존, 균질 마찰 + 가속 압손)를 상류로 쓰는
%   유량 이분법으로 결합한다. 상류 s는 (P_out, h_v) 지렛대로 재평가되어 라인
%   마찰에 의한 엔트로피 생성이 자동 반영된다. 결합 경로의 물성은 포화 테이블
%   지렛대(핫루프 py 호출 없음), n은 스텝당 탱크 상태에서 1회 평가(라인 압손
%   수 bar 구간에서 변화 미미).

%% Input
persistent m_prev_vap % 라인 결합 워밍 스타트 (직전 스텝 유량)
fluid = x.fluid;
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_NHNE_VapFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_NHNE_VapFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho1 = x.tank.rho_v;
h1 = x.tank.h_v;
s1 = x.tank.s_v;
T1 = x.tank.T;     % 상류 음속 조회 및 초크점 탐색 솔버 초기 추정값
cpv = x.tank.cp_v; % n 폴백 근사용
cvv = x.tank.cv_v; % n 폴백 근사용

% 하류(P2) 등엔트로피 상태 (InjState_VapFeed 결과) - alpha2 및 비초크 HEM에 사용
rho2 = x.inj.rho;
h2 = x.inj.h;
X2 = x.inj.X;         % 하류 건도 (등엔트로피 팽창 기준)
rho2_l = x.inj.rho_l; % 하류 포화 액상 밀도
rho2_v = x.inj.rho_v; % 하류 포화 증기상 밀도

A_inj = x.inj.A;
Cd_inj = x.inj.Cd;

%% System
% 초기화
mdot_SPC = 0;
mdot_HEM = 0;
mdot_inj = 0;
alpha2 = NaN;
S_slip = NaN;
hem_choked = false;
critical_pressure_ratio = NaN; % SPC 임계 압력비 (식 (11))
r_choke_HEM = NaN;             % HEM 플럭스 최대점 압력비 (초크점, 수치 탐색)
pressure_ratio = NaN;

% 실기체 등엔트로피 지수 n (논문 식 (8)) - Helmholtz EOS에서 n = rho*c^2/P와 정확히 동치
% 상류 증기상 상태 (T1, rho1)에서 기체 상 강제(state 2)로 음속을 조회하여 계산 (SPC 항 전용)
Props1 = fluid.GetProps(T1, rho1, 2);
if isfinite(Props1.c) && Props1.c > 0 && isfinite(Props1.P) && Props1.P > 0
    n_isen = rho1 * Props1.c^2 / Props1.P;
else
    warning('Inj_NHNE_VapFeed:IsenExpFallback', 'Sound speed lookup failed at (T1=%.2f K, rho1=%.2f kg/m^3). Falling back to n = cp/cv.', T1, rho1);
    n_isen = cpv / cvv; % 폴백: 비열비 근사 (이상기체 극한, ICF와 동일)
end

deltaP = P1 - P2;

if deltaP > 0 && P1 > 0
    pressure_ratio = P2 / P1;

    % --- SPC 질량 유량 (식 (10)/(12), 자체 임계비 식 (11)로 초크 판정) ---
    if isfinite(n_isen) && n_isen > 1
        critical_pressure_ratio = (2 / (n_isen + 1))^(n_isen / (n_isen - 1));
        if pressure_ratio <= critical_pressure_ratio
            sqrt_term = n_isen * rho1 * P1 * (2 / (n_isen + 1))^((n_isen + 1) / (n_isen - 1));
        else
            sqrt_term = 2 * rho1 * P1 * (n_isen / (n_isen - 1)) * ...
                (pressure_ratio^(2 / n_isen) - pressure_ratio^((n_isen + 1) / n_isen));
        end
        if sqrt_term >= 0
            mdot_SPC = Cd_inj * A_inj * sqrt(sqrt_term);
        else
            warning('Inj_NHNE_VapFeed:SPCSqrtNeg', 'Negative value in SPC sqrt. Setting mdot_SPC = 0.');
            mdot_SPC = 0;
        end
    else
        % n이 유효하지 않으면 SPI(비압축성)로 폴백 (Y = 1)
        warning('Inj_NHNE_VapFeed:InvalidN', 'Invalid isentropic exponent n (%.3f). Falling back to SPI for single-phase term.', n_isen);
        mdot_SPC = Cd_inj * A_inj * sqrt(2 * rho1 * deltaP);
    end

    % --- Zivi 슬립비 및 하류 보이드율 (식 (21), (24)) ---
    % 가중치 alpha2는 실제 하류 압력 P2까지의 등엔트로피 팽창 상태로 평가
    if ~isfinite(X2) || X2 >= 1
        alpha2 = 1; % 하류 전량 증기 -> 단상(SPC) 지배 (증기 배출의 일반적 경우)
    elseif X2 <= 0
        alpha2 = 0; % 하류 전량 액체 (완전 응축) -> HEM 지배
    elseif rho2_l > 0 && rho2_v > 0 && isfinite(rho2_l) && isfinite(rho2_v)
        S_slip = (rho2_l / rho2_v)^(1/3);
        alpha2 = 1 / (1 + ((1 - X2) / X2) * S_slip * (rho2_v / rho2_l));
    else
        warning('Inj_NHNE_VapFeed:InvalidSatDensity', 'Invalid downstream saturation densities (rho2_l=%.2f, rho2_v=%.2f). Defaulting to SPC-dominant flow (alpha2=1).', rho2_l, rho2_v);
        alpha2 = 1; % 증기 배출 시 alpha2~1이 물리적 기본값 (논문 실험 결과)
    end

    % --- HEM 질량 유량 (식 (16)) + 초크 캡 (논문 4.3절 방식) ---
    % 배압이 HEM 플럭스 최대점(초크점)보다 낮으면 초크점 상태로 HEM을 평가한다.
    [r_choke_HEM, choke_state] = FindHEMChokeRatioVap(fluid, P1, s1, h1, T1, rho1);
    if isfinite(r_choke_HEM) && pressure_ratio < r_choke_HEM && choke_state.valid
        hem_choked = true;
        rho2_HEM = choke_state.rho; % 초크점 상태로 캡
        h2_HEM = choke_state.h;
    else
        rho2_HEM = rho2; % 비초크: 실제 하류(P2) 상태 (InjState 결과)
        h2_HEM = h2;
        if ~isfinite(r_choke_HEM)
            warning('Inj_NHNE_VapFeed:HEMChokeSearchFail', 'HEM choke-point search failed. Using downstream (P2) state without cap.');
        end
    end
    if h1 >= h2_HEM
        mdot_HEM = Cd_inj * A_inj * rho2_HEM * sqrt(2 * (h1 - h2_HEM));
    else
        warning('Inj_NHNE_VapFeed:NegativeEnthalpyDrop', 'h1 (%.2f J/kg) < h2 (%.2f J/kg) for HEM calculation. Setting mdot_HEM = 0.', h1, h2_HEM);
        mdot_HEM = 0;
    end

    % --- FML 질량 유량 (식 (23), 증기상 유출) ---
    mdot_inj = alpha2 * mdot_SPC + (1 - alpha2) * mdot_HEM;

else
    % deltaP <= 0, no flow
    mdot_inj = 0;
    mdot_SPC = 0;
    mdot_HEM = 0;
    % alpha2, S_slip, r_choke_HEM은 초기값 NaN 유지
end

%% Feed line coupling (증기상 라인 결합)
use_feed = isfield(x, 'feed') && isfield(x.feed, 'mode') && x.feed.mode == 1 ...
           && ismethod(fluid, 'GetPropsPH');
P_out_line = x.tank.P; x_out_line = 1; dP_line = 0; % 무유량 기본값

if use_feed && mdot_inj > 0 && deltaP > 0
    CdA = Cd_inj * A_inj;
    % 브래킷: 결합 해는 무손실(탱크 직결) 유량 이하 [소량, mdot_직결]
    m_lo = 1e-5; m_hi = mdot_inj * 1.02;
    a = m_lo; b = m_hi;
    if ~isempty(m_prev_vap) && isfinite(m_prev_vap) && m_prev_vap > m_lo
        aw = max(m_lo, 0.7 * m_prev_vap); bw = min(m_hi, 1.3 * m_prev_vap);
        if vap_line_resid(x, aw, P2, n_isen, CdA) > 0 && vap_line_resid(x, bw, P2, n_isen, CdA) < 0
            a = aw; b = bw; % 직전 스텝 주변 워밍 스타트 성공
        end
    end
    ra = vap_line_resid(x, a, P2, n_isen, CdA);
    rb = vap_line_resid(x, b, P2, n_isen, CdA);
    if ra > 0 && rb < 0
        for it = 1:40
            m_mid = 0.5 * (a + b);
            if vap_line_resid(x, m_mid, P2, n_isen, CdA) > 0
                a = m_mid;
            else
                b = m_mid;
            end
            if (b - a) < 1e-4 * max(b, 1e-6), break; end
        end
        m_sol = 0.5 * (a + b);
        [~, dg] = vap_line_resid(x, m_sol, P2, n_isen, CdA);
        if dg.ok
            mdot_inj = m_sol;
            mdot_SPC = dg.mdot_SPC;
            mdot_HEM = dg.mdot_HEM;
            alpha2 = dg.alpha2;
            S_slip = dg.S_slip;
            hem_choked = dg.hem_choked;
            r_choke_HEM = dg.r_choke;
            pressure_ratio = P2 / dg.P_out;
            P_out_line = dg.P_out; x_out_line = dg.x_out; dP_line = dg.dP_line;
            m_prev_vap = m_sol;
        end
    elseif ra <= 0
        % 라인이 극소 유량도 통과 못 시킴 (말기 저압) -> 유량 0
        mdot_inj = 0; mdot_SPC = 0; mdot_HEM = 0;
        m_prev_vap = [];
    end
    % rb >= 0 (라인 손실이 무시할 수준): 탱크 직결 값 유지
end

%% Output
x.inj.n_isen = n_isen;
x.inj.ratio_Pcr = critical_pressure_ratio; % SPC 임계 압력비 (식 (11))
x.inj.ratio_Pcr_HEM = r_choke_HEM;         % HEM 초크점 압력비 (수치 탐색)
x.inj.ratio_P = pressure_ratio;
x.inj.choked = hem_choked;                 % HEM 캡 작동 여부
x.inj.S_slip = S_slip;
x.inj.alpha2 = alpha2;
% Output the component mass flow rates *including* Cd*A
x.inj.mdot_SPC = mdot_SPC;
x.inj.mdot_HEM = mdot_HEM;
% Output the total calculated mass flow rate
x.inj.mdot = mdot_inj;

% 급기 라인 진단값 (결합 시 갱신, 무유량이면 탱크압/건도1/손실0)
if use_feed
    x.feed.P_out = P_out_line;
    x.feed.x_out = x_out_line;
    x.feed.dP_line = dP_line;
end

end

function [r, dg] = vap_line_resid(x, m, P2, n_isen, CdA)
%vap_line_resid  결합 잔차: (라인 출구 상류로 평가한 FML 유량) - (가정 유량)
%   라인 통과 불가 시 음수 반환 (이분법이 유량을 낮추는 방향).
dg = struct('ok', false, 'P_out', NaN, 'x_out', NaN, 'dP_line', NaN, ...
            'mdot_SPC', NaN, 'mdot_HEM', NaN, 'alpha2', NaN, 'S_slip', NaN, ...
            'hem_choked', false, 'r_choke', NaN);
fo = Feed_Line(x, m, 'vap');
if ~fo.ok
    r = -max(m, 1e-6);
    return;
end
h1 = x.tank.h_v;
st = N2O_SatTable(fo.P_out);
if ~st.ok
    r = -max(m, 1e-6);
    return;
end
% 라인 출구 상류 상태: (P_out, h_v) 지렛대 -> s1 (마찰 엔트로피 생성 반영)
Xc = min(max((h1 - st.hl) / max(st.hv - st.hl, eps), 0), 1);
s1c = st.sl + Xc * (st.sv - st.sl);
[mdot_c, dgi] = fml_vap_lever(fo.P_out, fo.rho_out, h1, s1c, P2, n_isen, CdA);
r = mdot_c - m;
dg = dgi;
dg.ok = true;
dg.P_out = fo.P_out; dg.x_out = fo.x_out; dg.dP_line = fo.dP_line;
end

function [mdot, dg] = fml_vap_lever(P1, rho1, h1, s1, P2, n, CdA)
%fml_vap_lever  FML 증기상 유량 (식 (23)) - 포화 테이블 지렛대 전용 고속판
%   SPC: 실기체 n (스텝당 1회 평가값 재사용). HEM: 지렛대 등엔트로피 플럭스의
%   최대점(초크점) 캡 (황금분할, 순수 MATLAB). 과열 영역은 X<=1 클램프로
%   포화증기 근사 (증기상 알짜 기여는 alpha2~1로 SPC 지배적).
dg = struct('ok', true, 'P_out', NaN, 'x_out', NaN, 'dP_line', NaN, ...
            'mdot_SPC', 0, 'mdot_HEM', 0, 'alpha2', 1, 'S_slip', NaN, ...
            'hem_choked', false, 'r_choke', NaN);
rr = min(max(P2 / P1, 1e-6), 1);

% --- SPC (식 (10)/(12)) ---
if isfinite(n) && n > 1
    rcr = (2 / (n + 1))^(n / (n - 1));
    if rr <= rcr
        term = n * rho1 * P1 * (2 / (n + 1))^((n + 1) / (n - 1));
    else
        term = 2 * rho1 * P1 * (n / (n - 1)) * (rr^(2 / n) - rr^((n + 1) / n));
    end
else
    term = 2 * rho1 * max(P1 - P2, 0); % SPI 폴백
end
mdot_SPC = CdA * sqrt(max(term, 0));

% --- alpha2: 하류(P2) 등엔트로피 지렛대 상태 + Zivi 슬립 ---
alpha2 = 1; S_slip = NaN;
s2t = N2O_SatTable(P2);
if s2t.ok
    X2 = (s1 - s2t.sl) / max(s2t.sv - s2t.sl, eps);
    if X2 <= 0
        alpha2 = 0;
    elseif X2 < 1
        S_slip = (s2t.rhol / s2t.rhov)^(1/3);
        alpha2 = 1 / (1 + ((1 - X2) / X2) * S_slip * (s2t.rhov / s2t.rhol));
    end
end

% --- HEM: 지렛대 플럭스 + 초크 캡 (황금분할) ---
mdot_HEM = 0; hem_choked = false; r_choke = NaN;
if alpha2 < 1 - 1e-9 % 전량 증기(alpha2=1)면 HEM 기여 0 -> 탐색 생략
    phi = (sqrt(5) - 1) / 2;
    a = 0.30; b = 0.995;
    x1 = b - phi * (b - a); x2 = a + phi * (b - a);
    f1 = lever_flux(x1 * P1, s1, h1); f2 = lever_flux(x2 * P1, s1, h1);
    for it = 1:12
        if f1 >= f2
            b = x2; x2 = x1; f2 = f1; x1 = b - phi * (b - a);
            f1 = lever_flux(x1 * P1, s1, h1);
        else
            a = x1; x1 = x2; f1 = f2; x2 = a + phi * (b - a);
            f2 = lever_flux(x2 * P1, s1, h1);
        end
    end
    if f1 >= f2, r_choke = x1; else, r_choke = x2; end
    if rr < r_choke
        hem_choked = true;
        G = lever_flux(r_choke * P1, s1, h1); % 초크점 캡
    else
        G = lever_flux(P2, s1, h1);
    end
    if isfinite(G) && G > 0
        mdot_HEM = CdA * G;
    end
end

mdot = alpha2 * mdot_SPC + (1 - alpha2) * mdot_HEM;
dg.mdot_SPC = mdot_SPC; dg.mdot_HEM = mdot_HEM;
dg.alpha2 = alpha2; dg.S_slip = S_slip;
dg.hem_choked = hem_choked; dg.r_choke = r_choke;
end

function G = lever_flux(Pe, s1, h1)
%lever_flux  등엔트로피(s=s1) 지렛대 상태의 HEM 질량 플럭스 G = rho2*sqrt(2*(h1-h2))
st = N2O_SatTable(Pe);
if ~st.ok
    G = -Inf;
    return;
end
X = min(max((s1 - st.sl) / max(st.sv - st.sl, eps), 0), 1);
h2 = st.hl + X * (st.hv - st.hl);
rho2 = 1 / (X / st.rhov + (1 - X) / st.rhol);
if h1 > h2 && isfinite(rho2)
    G = rho2 * sqrt(2 * (h1 - h2));
else
    G = -Inf;
end
end

function [r_best, state_best] = FindHEMChokeRatioVap(fluid, P1, s1, h1, guessT, guessRho)
%FindHEMChokeRatioVap  HEM 질량 플럭스 최대점(초크점) 압력비 탐색 (증기상)
%   G(r) = rho2(r*P1) * sqrt(2*(h1 - h2(r*P1))),  s = s1 등엔트로피 기준.
%   단봉 함수이므로 황금분할 탐색. 상류 상태 (P1, s1)가 직전 호출과 거의 같으면
%   캐시를 재사용한다.
persistent cP1 cs1 cr cstate
% 캐시 허용 오차: 직접 플래시 지원 모델(CoolProp)은 재탐색이 저렴하므로 더 조밀하게
if ismethod(fluid, 'GetPropsPS')
    tol_cache = 0.001;
else
    tol_cache = 0.005;
end
if ~isempty(cP1) && ~isempty(cr) && isfinite(cr) && ...
        abs(P1 - cP1) <= tol_cache * cP1 && abs(s1 - cs1) <= tol_cache * abs(cs1)
    r_best = cr;
    state_best = cstate;
    return;
end

phi = (sqrt(5) - 1) / 2; % 황금비
if ~isempty(cr) && isfinite(cr)
    a = max(0.05, cr - 0.15); b = min(0.995, cr + 0.15); n_iter = 12; % 직전 초크점 주변 재탐색
else
    a = 0.30; b = 0.995; n_iter = 16; % 최초 탐색 (기체 초크점은 통상 0.5~0.6 부근)
end

x1 = b - phi * (b - a); x2 = a + phi * (b - a);
[f1, st1] = hem_flux(x1); [f2, st2] = hem_flux(x2);
for it = 1:n_iter
    if f1 >= f2
        b = x2; x2 = x1; f2 = f1; st2 = st1;
        x1 = b - phi * (b - a); [f1, st1] = hem_flux(x1);
    else
        a = x1; x1 = x2; f1 = f2; st1 = st2;
        x2 = a + phi * (b - a); [f2, st2] = hem_flux(x2);
    end
end
if f1 >= f2
    r_best = x1; state_best = st1; f_best = f1;
else
    r_best = x2; state_best = st2; f_best = f2;
end

if ~isfinite(f_best) || ~state_best.valid
    r_best = NaN;
    state_best = struct('valid', false, 'T', NaN, 'rho', NaN, 'h', NaN, 'X', NaN, 'rho_l', NaN, 'rho_v', NaN);
else
    cP1 = P1; cs1 = s1; cr = r_best; cstate = state_best; % 유효한 결과만 캐시
end

    function [G, st] = hem_flux(r)
        st = SolveIsentropicStateVap(fluid, r * P1, s1, guessT, guessRho);
        if st.valid && h1 > st.h
            G = st.rho * sqrt(2 * (h1 - st.h));
        else
            G = -Inf;
        end
    end
end

function st = SolveIsentropicStateVap(fluid, P_target, s_target, guessT, guessRho)
%SolveIsentropicStateVap  목표 압력까지의 등엔트로피 팽창 상태 계산 + 해 검증 (증기상)
%   (InjState_VapFeed와 동일하게 GetProps의 상 플래그 2(기체)를 사용. 잔차 무차원화 및
%   해 검증으로 가짜 근(예: 밀도 상한에 붙은 액체급 해)이 유량 계산에 쓰이는 것을 방지.)

% CoolProp 등 직접 P-s 플래시 지원 모델: 내장 플래시 사용 (가짜 근 원천 차단)
if ismethod(fluid, 'GetPropsPS')
    Props = fluid.GetPropsPS(P_target, s_target);
    st.T = Props.T; st.rho = Props.rho; st.h = Props.h; st.X = Props.X;
    st.rho_l = Props.rho_l; st.rho_v = Props.rho_v;
    st.valid = Props.state ~= -1 && isfinite(Props.rho) && Props.rho > 0 && isfinite(Props.h);
    return;
end

lb = [183, 2.7];
ub = [309, 1236];
pFunc = @(v) [ (getfield(fluid.GetProps(v(1), v(2), 2), 'P') - P_target) / max(abs(P_target), 1);
               (getfield(fluid.GetProps(v(1), v(2), 2), 's') - s_target) / max(abs(s_target), 1) ];
v = lsqnonlin(pFunc, [guessT, guessRho], lb, ub, optimset('Display', 'off', 'TolFun', 1e-12));
Props = fluid.GetProps(v(1), v(2), 2);
st.T = v(1);
st.rho = Props.rho;
st.h = Props.h;
st.X = Props.X;
st.rho_l = Props.rho_l;
st.rho_v = Props.rho_v;
% 해 검증: 잔차 및 경계 밀착 여부
P_err = abs(Props.P - P_target) / max(abs(P_target), 1);
s_err = abs(Props.s - s_target) / max(abs(s_target), 1);
on_bound = (v(2) >= 0.98 * ub(2)) || (v(1) <= lb(1) + 0.5) || (v(1) >= ub(1) - 0.5);
st.valid = isfinite(Props.rho) && isfinite(Props.h) && P_err < 5e-3 && s_err < 5e-3 && ~on_bound;
end
