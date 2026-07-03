function [x] = InjState_VapFeed(x)
%% Input
fluid = x.fluid;
% Pc = x.comb.P; % 기존 연소실 압력 사용 코드 주석 처리
P_downstream = x.comb.Pinj; % 인젝터 후단 압력으로 Pinj 사용

% Check if P_downstream is valid, otherwise use Pc as fallback or handle error
if ~isfinite(P_downstream) || P_downstream <= 0
    warning('InjState_VapFeed:InvalidPinj', 'Pinj (%.2f Pa) is invalid. Falling back to Pc (%.2f Pa).', P_downstream, x.comb.P);
    P_downstream = x.comb.P; % Fallback to Pc if Pinj is not valid
    if ~isfinite(P_downstream) || P_downstream <= 0
        error('InjState_VapFeed:InvalidPcFallback', 'Fallback Pc (%.2f Pa) is also invalid. Cannot proceed.', P_downstream);
    end
end

s1 = x.tank.s_v;  
geussT = x.tank.T;
geussRho = x.tank.rho_v;

%% System
% Optimized objective function: Call GetProps only once per iteration
% pFunc = @(v) [ getfield(fluid.GetProps(v(1), v(2), 2), 'P') - Pc;
% 			   getfield(fluid.GetProps(v(1), v(2), 2), 's') - s1 ];
pFunc = @objective_helper_nested; % 중첩 함수 핸들로 변경

% 솔버 초기 추정값으로 탱크의 온도와 밀도를 사용
lb = [183, 2.7];
ub = [309, 1236];
v = lsqnonlin(pFunc, [geussT, geussRho], lb, ub, optimset('Display', 'off', 'TolFun', 1e-10));
T2 = v(1); 
rho2 = v(2); 

% 인젝터 유동을 증기상으로 고정하기 위해 GetProps의 세 번째 인자로 2를 전달
Props = fluid.GetProps(T2, rho2, 2);

%% Output
% 상태 변수
x.inj.state = Props.state; % -1: 오류, 0: 액체, 1: 포화, 2: 기체
x.inj.P = Props.P; % Pc를 사용하는 대신 Props.P를 사용 (MD 파일 형식 일치)
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

    % 중첩 함수 (Nested Function) 정의
    % v_params는 lsqnonlin에서 전달하는 현재 반복의 [T, rho] 값
    function F_out = objective_helper_nested(v_params)
        % fluid, P_downstream, s1은 외부 함수 InjState_VapFeed의 변수를 사용합니다.
        temp_props = fluid.GetProps(v_params(1), v_params(2), 2); % GetProps 1회 호출
        F_out = [temp_props.P - P_downstream; temp_props.s - s1]; % Pc 대신 P_downstream 사용
    end

end 