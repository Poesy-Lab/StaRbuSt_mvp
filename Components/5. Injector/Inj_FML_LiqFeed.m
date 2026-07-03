function [x] = Inj_FML_LiqFeed(x)
%Inj_FML_LiqFeed  FML(Foletti-Magni-La Luna) 2상 질량 유량 모델 - 액상 유출
%   출처: La Luna et al., "A Two-Phase Mass Flow Rate Model for Nitrous
%   Oxide Based on Void Fraction", Aerospace 2022, 9(12), 828. (식 (22))
%   선행 조건: InjState_LiqFeed가 먼저 호출되어 하류 등엔트로피 상태가
%   x.inj.*에 준비되어 있어야 함.

%% Input
fluid = x.fluid;
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_FML_LiqFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_FML_LiqFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho1 = x.tank.rho_l;
h1 = x.tank.h_l;
s1 = x.tank.s_l;
T1 = x.tank.T;     % 상류 음속 조회용 (n 정확 계산)
cp1 = x.tank.cp_l; % n 폴백 근사용
cv1 = x.tank.cv_l; % n 폴백 근사용

% 하류 등엔트로피 상태 (InjState_LiqFeed가 먼저 호출되어 있어야 함)
rho2 = x.inj.rho;
h2 = x.inj.h;
X2 = x.inj.X;         % 하류 건도 (등엔트로피 팽창 기준)
rho2_l = x.inj.rho_l; % 하류 포화 액상 밀도
rho2_v = x.inj.rho_v; % 하류 포화 증기상 밀도
T2_guess = x.inj.T;   % 초크 시 재계산용 초기 추정값
rho2_guess = x.inj.rho;

A_inj = x.inj.A;
Cd_inj = x.inj.Cd;

%% System
% 초기화
mdot_SPC = 0;
mdot_HEM = 0;
mdot_inj = 0;
alpha2 = NaN;
S_slip = NaN;
is_choked = false;
critical_pressure_ratio = NaN;
pressure_ratio = NaN;

% 실기체 등엔트로피 지수 n (논문 식 (8)) - Helmholtz EOS에서 n = rho*c^2/P와 정확히 동치
% 상류 액상 상태 (T1, rho1)에서 액체 상 강제(state 0)로 음속을 조회하여 계산
Props1 = fluid.GetProps(T1, rho1, 0);
if isfinite(Props1.c) && Props1.c > 0 && isfinite(Props1.P) && Props1.P > 0
    n_isen = rho1 * Props1.c^2 / Props1.P;
else
    warning('Inj_FML_LiqFeed:IsenExpFallback', 'Sound speed lookup failed at (T1=%.2f K, rho1=%.2f kg/m^3). Falling back to n = cp/cv.', T1, rho1);
    n_isen = cp1 / cv1; % 폴백: 비열비 근사 (이상기체 극한)
end

deltaP = P1 - P2;

if deltaP > 0 && P1 > 0
    pressure_ratio = P2 / P1;

    % --- 초킹 판정 (SPC/HEM 공통 단일 기준, 식 (11)) ---
    if isfinite(n_isen) && n_isen > 1
        critical_pressure_ratio = (2 / (n_isen + 1))^(n_isen / (n_isen - 1));
        is_choked = (pressure_ratio <= critical_pressure_ratio);
    else
        warning('Inj_FML_LiqFeed:InvalidN', 'Invalid isentropic exponent n (%.3f). Falling back to SPI for single-phase term.', n_isen);
    end

    % --- SPC 질량 유량 (식 (10)/(12)) ---
    if isfinite(n_isen) && n_isen > 1
        if is_choked
            sqrt_term = n_isen * rho1 * P1 * (2 / (n_isen + 1))^((n_isen + 1) / (n_isen - 1));
        else
            sqrt_term = 2 * rho1 * P1 * (n_isen / (n_isen - 1)) * ...
                (pressure_ratio^(2 / n_isen) - pressure_ratio^((n_isen + 1) / n_isen));
        end
        if sqrt_term >= 0
            mdot_SPC = Cd_inj * A_inj * sqrt(sqrt_term);
        else
            warning('Inj_FML_LiqFeed:SPCSqrtNeg', 'Negative value in SPC sqrt. Setting mdot_SPC = 0.');
            mdot_SPC = 0;
        end
    else
        % n이 유효하지 않으면 SPI(비압축성)로 폴백 (Y = 1)
        mdot_SPC = Cd_inj * A_inj * sqrt(2 * rho1 * deltaP);
    end

    % --- 초크 시 하류 등엔트로피 상태 재계산 (P2_eff = P1 * 임계 압력비) ---
    if is_choked
        P2_eff = P1 * critical_pressure_ratio;
        try
            [rho2, h2, X2, rho2_l, rho2_v] = SolveIsentropicState(fluid, P2_eff, s1, T2_guess, rho2_guess);
        catch ME_state
            warning('Inj_FML_LiqFeed:ChokedStateFail', 'Failed to re-solve choked downstream state: %s. Using InjState values at P2.', ME_state.message);
        end
    end

    % --- HEM 질량 유량 (식 (16)) ---
    if h1 >= h2
        mdot_HEM = Cd_inj * A_inj * rho2 * sqrt(2 * (h1 - h2));
    else
        warning('Inj_FML_LiqFeed:NegativeEnthalpyDrop', 'h1 (%.2f J/kg) < h2 (%.2f J/kg) for HEM calculation. Setting mdot_HEM = 0.', h1, h2);
        mdot_HEM = 0;
    end

    % --- Zivi 슬립비 및 하류 보이드율 (식 (21), (24)) ---
    if ~isfinite(X2) || X2 <= 0
        alpha2 = 0; % 하류 전량 액체 -> 단상(SPC) 지배
    elseif X2 >= 1
        alpha2 = 1; % 하류 전량 증기 (완전 플래싱) -> HEM 지배
    elseif rho2_l > 0 && rho2_v > 0 && isfinite(rho2_l) && isfinite(rho2_v)
        S_slip = (rho2_l / rho2_v)^(1/3);
        alpha2 = 1 / (1 + ((1 - X2) / X2) * S_slip * (rho2_v / rho2_l));
    else
        warning('Inj_FML_LiqFeed:InvalidSatDensity', 'Invalid downstream saturation densities (rho2_l=%.2f, rho2_v=%.2f). Defaulting to HEM-dominant flow (alpha2=1).', rho2_l, rho2_v);
        alpha2 = 1; % Inj_NHNE_LiqFeed의 HEM 지배 폴백과 동일한 방침
    end

    % --- FML 질량 유량 (식 (22), 액상 유출) ---
    mdot_inj = (1 - alpha2) * mdot_SPC + alpha2 * mdot_HEM;

else
    % deltaP <= 0, no flow
    mdot_inj = 0;
    mdot_SPC = 0;
    mdot_HEM = 0;
    % alpha2, S_slip은 초기값 NaN 유지
end

%% Output
x.inj.n_isen = n_isen;
x.inj.ratio_Pcr = critical_pressure_ratio;
x.inj.ratio_P = pressure_ratio;
x.inj.choked = is_choked;
x.inj.S_slip = S_slip;
x.inj.alpha2 = alpha2;
% Output the component mass flow rates *including* Cd*A
x.inj.mdot_SPC = mdot_SPC;
x.inj.mdot_HEM = mdot_HEM;
% Output the total calculated mass flow rate
x.inj.mdot = mdot_inj;

end

function [rho2, h2, X2, rho2_l, rho2_v] = SolveIsentropicState(fluid, P_target, s1, guessT, guessRho)
%SolveIsentropicState  목표 압력 P_target까지의 등엔트로피 팽창 상태 계산
%   초크 조건에서 임계 압력 기준의 하류 상태를 구하기 위해 사용.
%   (InjState_LiqFeed와 동일한 lsqnonlin 방식)
pFunc = @(v) [ getfield(fluid.GetProps(v(1), v(2)), 'P') - P_target;
               getfield(fluid.GetProps(v(1), v(2)), 's') - s1 ];
lb = [183, 2.7];
ub = [309, 1236];
v = lsqnonlin(pFunc, [guessT, guessRho], lb, ub, optimset('Display', 'off', 'TolFun', 1e-10));
Props = fluid.GetProps(v(1), v(2), 1);
rho2 = Props.rho;
h2 = Props.h;
X2 = Props.X;
rho2_l = Props.rho_l;
rho2_v = Props.rho_v;
end
