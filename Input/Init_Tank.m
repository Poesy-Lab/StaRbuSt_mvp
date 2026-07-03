function [x] = Init_Tank(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환
if isfield(u.tank, 'V') % 탱크 부피를 직접 설정한 경우
	switch unit.tank.V
		case "m^3"
			V = u.tank.V;
		case "L"
			V = u.tank.V * 1e-3;
		case "cm^3"
			V = u.tank.V * 1e-6;
		case "ft^3"
			V = u.tank.V * 0.0283168;
		case "gal"
			V = u.tank.V * 3.78541;
		otherwise
			error("허용된 단위: m^3, L, cm^3, ft^3, gal만 입력 가능");
	end
elseif isfield(u.tank, 'd') && isfield(u.tank, 'h') % 원통형 탱크의 직경과 높이로부터 부피 계산
	% 직경 단위 변환
	switch unit.tank.d
		case "m"
			d = u.tank.d;
		case "mm"
			d = u.tank.d * 1e-3;
		case "cm"
			d = u.tank.d * 1e-2;
		case "in"
			d = u.tank.d * 0.0254;
		otherwise
			error("허용된 단위: m, mm, cm, in만 입력 가능");
	end
	
	% 높이 단위 변환
	switch unit.tank.h
		case "m"
			h = u.tank.h;
		case "mm"
			h = u.tank.h * 1e-3;
		case "cm"
			h = u.tank.h * 1e-2;
		case "in"
			h = u.tank.h * 0.0254;
		otherwise
			error("허용된 단위: m, mm, cm, in만 입력 가능");
	end
	
	% 원통형 탱크 부피 계산 (m^3)
	V = pi * (d/2)^2 * h;
    A = pi * (d/2)^2; % <<< 탱크 단면적 계산 추가
else
	error("탱크 부피를 직접 설정하거나 직경과 높이를 설정해야 합니다.");
end

% tank.m, kg
switch unit.tank.m
	case "kg"
		m = u.tank.m;
	case "g"
		m = u.tank.m * 1e-3;
	case "lb"
		m = u.tank.m * 0.453592;
	case "oz"
		m = u.tank.m * 0.0283495;
	otherwise
		error("허용된 단위: kg, g, lb, oz만 입력 가능");
end

% tank.T, K
switch unit.tank.T
	case "K"
		T = u.tank.T;
	case "°C"
		T = u.tank.T + 273.15;
	case "°F"
		T = (u.tank.T - 32) * 5/9 + 273.15;
	case "C"
		T = u.tank.T + 273.15;
	case "F"
		T = (u.tank.T - 32) * 5/9 + 273.15;
	otherwise
		error("허용된 단위: K, °C, °F, C, F만 입력 가능");
end

% tank.fluid
switch u.tank.fluid
	case "N2O"
		fluid = N2O();
	case "CO2"
		fluid = CO2();
	otherwise
		error("N2O, CO2 만 입력 가능");
end


%% 상태량 초기화
% 탱크 상태량 불러오기
x.tank.V = V;
x.tank.A = A; % <<< 계산된 단면적 저장
x.tank.m = m;
x.tank.T = T;
x.tank.fluid = fluid;
x.tank.rho = x.tank.m / x.tank.V;
Props = fluid.GetProps(x.tank.T, x.tank.rho);

% 상태 변수
x.tank.P = Props.P; % 압력
x.tank.state = Props.state; % 상태 변수
x.tank.X = Props.X; % 건도

% 액체 및 증기 질량 계산 및 저장
x.tank.m_v = x.tank.m * x.tank.X;     % 증기 질량
x.tank.m_l = x.tank.m * (1 - x.tank.X); % 액체 질량

% 증기상 물성
x.tank.rho_v = Props.rho_v; % kg/m^3
x.tank.u_v = Props.u_v; % J/kg
x.tank.s_v = Props.s_v; % J/kg-K
x.tank.h_v = Props.h_v; % J/kg
x.tank.cp_v = Props.cp_v; % J/kg-K
x.tank.cv_v = Props.cv_v; % J/kg-K
x.tank.c_v = Props.c_v; % m/s

% 액상 물성
x.tank.rho_l = Props.rho_l; % kg/m^3
x.tank.u_l = Props.u_l; % J/kg
x.tank.s_l = Props.s_l; % J/kg-K
x.tank.h_l = Props.h_l; % J/kg
x.tank.cp_l = Props.cp_l; % J/kg-K
x.tank.cv_l = Props.cv_l; % J/kg-K
x.tank.c_l = Props.c_l; % m/s

% 혼합물 물성
x.tank.u = Props.u; % J/kg
x.tank.s = Props.s; % J/kg-K
x.tank.h = Props.h; % J/kg
x.tank.cp = Props.cp; % J/kg-K
x.tank.cv = Props.cv; % J/kg-K
x.tank.c = Props.c; % m/s
x.tank.S = x.tank.m * Props.s; % J/K
x.tank.H = x.tank.m * Props.h; % J

end 