function [x] = InjState_LiqFeed(x)
%% Input
fluid = x.fluid;
% Pc = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P_downstream = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P_downstream is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P_downstream) || P_downstream <= 0
    warning('InjState_LiqFeed:InvalidPinj', 'Pinj (%.2f Pa) is invalid. Falling back to Pc (%.2f Pa).', P_downstream, x.comb.P);
    P_downstream = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P_downstream) || P_downstream <= 0
        error('InjState_LiqFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) is also invalid. Cannot proceed.', P_downstream);
    end
end

s1 = x.tank.s_l;
geussT = x.tank.T;
geussRho = x.tank.rho_l;

%% System
% 엔트로피 오차에 가중치 부여 -> 제거
pFunc = @(v) [ (getfield(fluid.GetProps(v(1), v(2)), 'P') - P_downstream);
			   (getfield(fluid.GetProps(v(1), v(2)), 's') - s1) ];

% 솔버 초기 추정값으로 탱크의 온도와 액상 밀도를 사용 (InjState_VapFeed.m 형식 참고)
lb = [183, 2.7];
ub = [309, 1236];
v = lsqnonlin(pFunc, [geussT, geussRho], lb, ub, optimset('Display', 'off', 'TolFun', 1e-10));
T2 = v(1); 
rho2 = v(2); 

Props = fluid.GetProps(T2, rho2, 1);

%% Output
% 상태 변수
x.inj.state = Props.state; % -1: 오류, 0: 액체, 1: 포화, 2: 기체
x.inj.P = Props.P; % Pa
x.inj.T = Props.T; % K
x.inj.X = Props.X; % 건도

% 혼합물 물성
x.inj.rho = Props.rho; %kg/m^3
x.inj.u = Props.u; % J/kg
x.inj.s = Props.s; % J/kg-K
x.inj.h = Props.h; % J/kg
x.inj.cp = Props.cp; % J/kg-K
x.inj.cv = Props.cv; % J/kg-K

% 증기상 물성
x.inj.rho_v = Props.rho_v; % kg/m^3
x.inj.u_v = Props.u_v; % J/kg
x.inj.s_v = Props.s_v; % J/kg-K
x.inj.h_v = Props.h_v; % J/kg
x.inj.cp_v = Props.cp_v; % J/kg-K
x.inj.cv_v = Props.cv_v; % J/kg-K

% 액상 물성
x.inj.rho_l = Props.rho_l; % kg/m^3
x.inj.u_l = Props.u_l; % J/kg
x.inj.s_l = Props.s_l; % J/kg-K
x.inj.h_l = Props.h_l; % J/kg
x.inj.cp_l = Props.cp_l; % J/kg-K
x.inj.cv_l = Props.cv_l; % J/kg-K

end 