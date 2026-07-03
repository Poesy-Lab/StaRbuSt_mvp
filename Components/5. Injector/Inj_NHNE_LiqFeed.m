function [x] = Inj_NHNE_LiqFeed(x)
%% Input
fluid = x.fluid;
% P2 = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P2 = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P2 (Pinj) is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P2) || P2 <= 0
    warning('Inj_NHNE_LiqFeed:InvalidPinj', 'Pinj (%.2f Pa) used as P2 is invalid. Falling back to Pc (%.2f Pa).', P2, x.comb.P);
    P2 = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P2) || P2 <= 0
        error('Inj_NHNE_LiqFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) used as P2 is also invalid. Cannot proceed.', P2);
    end
end

P1 = x.tank.P;
rho1 = x.tank.rho_l;
rho2 = x.inj.rho; % This rho is calculated by InjState_LiqFeed called before this
h1 = x.tank.h_l;
h2 = x.inj.h; % This h is calculated by InjState_LiqFeed called before this

% Saturation pressure at upstream temperature/state
% Approximation: Use tank pressure if not supercharged or subcooled significantly.
% More accurate: Calculate Psat(T_tank) if possible.
Pv1 = x.tank.P; % Approximation - Consider improving if necessary
% Pv1 = x.inj.P; % Approximation - Consider improving if necessary

% 인젝터 면적 계산 (메인 + 서브)
A_inj = x.inj.A; % 메인 인젝터 면적
if isfield(x, 'subinj') && isfield(x.subinj, 'A') && x.subinj.A > 0
    A_inj = A_inj + x.subinj.A; % 서브 인젝터 면적 추가
end

Cd_inj = x.inj.Cd; % 토출 계수
L_inj = x.inj.L;

%% System
deltaP = P1 - P2;
mdot_inc_val = 0; % Initialize to avoid potential undefined error later
mdot_HEM_val = 0; % Initialize
mdot_inj = 0; % Initialize
kappa = NaN;    % Initialize as NaN to indicate not calculated if deltaP <= 0

if deltaP > 0
    % Calculate kappa directly without complex check
    kappa = sqrt((P1 - P2) / (Pv1 - P2));
    % tau_b = sqrt(3/2 * (rho1 / (Pv1 - P2)));
    % tau_r = (L_inj * 1e3) * sqrt(rho1 / (2 * deltaP));
    % kappa = tau_b / tau_r;

    % Calculate weights directly without special checks
    w_inc = kappa / (1 + kappa); % Dyer's original: 1 - 1 / (1 + kappa)
    w_hem = 1 / (1 + kappa);
    
    % Calculate CdA flow rate term including Cd*A
    mdot_inc = Cd_inj * A_inj * sqrt(2 * rho1 * deltaP);
    
    % Calculate HEM flow rate term including Cd*A
    mdot_HEM = Cd_inj * A_inj * rho2 * sqrt(2 * (h1 - h2));
    
    % Calculate final NHNE mass flow rate using weighted components
    mdot_inj = w_inc * mdot_inc + w_hem * mdot_HEM;
    
else
    % deltaP <= 0, no flow
    mdot_inj = 0;
    % kappa remains NaN
    mdot_inc = 0;
    mdot_HEM = 0;
end

%% Output
x.inj.kappa = kappa;
% Output the component mass flow rates *including* Cd*A
x.inj.mdot_inc = mdot_inc; 
x.inj.mdot_HEM = mdot_HEM; 
% Output the total calculated mass flow rate
x.inj.mdot = mdot_inj;

end