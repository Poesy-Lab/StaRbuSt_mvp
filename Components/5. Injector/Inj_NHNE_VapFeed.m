function [x] = Inj_NHNE_VapFeed(x)
%Inj_NHNE_VapFeed  FML(Foletti-Magni-La Luna) 질량 유량 모델 - 증기상 유출
%   출처: La Luna et al., "A Two-Phase Mass Flow Rate Model for Nitrous
%   Oxide Based on Void Fraction", Aerospace 2022, 9(12), 828. (식 (23))
%   - 가중치 alpha2: 하류(P2) 등엔트로피 상태의 보이드율 (InjState_VapFeed 결과)
%   - HEM 항: 등엔트로피 팽창 경로 위 질량 플럭스의 최대점(초크점)에서 캡
%     (논문 4.3절의 수치 탐색 방식; SPC 임계비와는 별개의 기준)
%   선행 조건: InjState_VapFeed가 먼저 호출되어 하류 등엔트로피 상태가
%   x.inj.*에 준비되어 있어야 함.

%% Input
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

end

function [r_best, state_best] = FindHEMChokeRatioVap(fluid, P1, s1, h1, guessT, guessRho)
%FindHEMChokeRatioVap  HEM 질량 플럭스 최대점(초크점) 압력비 탐색 (증기상)
%   G(r) = rho2(r*P1) * sqrt(2*(h1 - h2(r*P1))),  s = s1 등엔트로피 기준.
%   단봉 함수이므로 황금분할 탐색. 상류 상태 (P1, s1)가 직전 호출과 거의 같으면
%   캐시를 재사용한다.
persistent cP1 cs1 cr cstate
if ~isempty(cP1) && ~isempty(cr) && isfinite(cr) && ...
        abs(P1 - cP1) <= 0.005 * cP1 && abs(s1 - cs1) <= 0.005 * abs(cs1)
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
