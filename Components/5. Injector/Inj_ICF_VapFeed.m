function [x] = Inj_ICF_VapFeed(x)
%% Input
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_ICF_VapFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_ICF_VapFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho_v = x.tank.rho_v;
cpv = x.tank.cp_v;
cvv = x.tank.cv_v;

% 인젝터 면적 계산 (메인 + 서브)
A_inj = x.inj.A; % 메인 인젝터 면적
if isfield(x, 'subinj') && isfield(x.subinj, 'A') && x.subinj.A > 0
    A_inj = A_inj + x.subinj.A; % 서브 인젝터 면적 추가
end
Cd_inj = x.inj.Cd;

gamma = cpv / cvv; % 비열비 계산

%% System
% Handle potential division by zero or NaN if P1 is zero or negative
if P1 <= 0
    pressure_ratio = Inf; % Ensure non-choked
else
    pressure_ratio = P2 / P1;
end

% Handle potential NaN gamma if cpv or cvv is NaN/zero
if isnan(gamma) || gamma <= 1
    warning('Inj_ICF_VapFeed:InvalidGamma', 'Invalid gamma (%.2f) calculated. Setting mdot_inj = 0.', gamma);
    mdot_inj = 0;
    critical_pressure_ratio = NaN;
else
    % 임계 압력비 계산 (choked flow 조건)
    critical_pressure_ratio = (2 / (gamma + 1))^(gamma / (gamma - 1));

    % 유량 계산
    if pressure_ratio <= critical_pressure_ratio
        % 초크 유동 (Choked flow)
        choked_term = (2 / (gamma + 1))^((gamma + 1) / (gamma - 1));
        % Ensure term inside sqrt is non-negative
        sqrt_term = gamma * P1 * rho_v * choked_term;
        if sqrt_term >= 0
            mdot_inj = Cd_inj * A_inj * sqrt(sqrt_term);
        else
            warning('Inj_ICF_VapFeed:ChokedSqrtNeg', 'Negative value encountered in choked flow sqrt. Setting mdot_inj = 0.');
            mdot_inj = 0;
        end
    else
        % 비초크 유동 (Non-choked flow)
        term1 = (pressure_ratio)^(2 / gamma);
        term2 = (pressure_ratio)^((gamma + 1) / gamma);
        % Ensure term inside sqrt is non-negative
        sqrt_term = (2 * gamma / (gamma - 1)) * rho_v * P1 * (term1 - term2);
         if sqrt_term >= 0
            mdot_inj = Cd_inj * A_inj * sqrt(sqrt_term);
        else
             warning('Inj_ICF_VapFeed:NonChokedSqrtNeg', 'Negative value encountered in non-choked flow sqrt. Setting mdot_inj = 0.');
            mdot_inj = 0;
        end
    end
end

%% Output
x.inj.ratio_Pcr = critical_pressure_ratio;
x.inj.ratio_P = pressure_ratio;
x.inj.mdot = mdot_inj;

end 