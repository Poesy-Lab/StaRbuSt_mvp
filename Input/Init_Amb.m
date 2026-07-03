function [x] = Init_Amb(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환
% amb.P, Pa
switch unit.amb.P
	case "Pa"
		P = u.amb.P;
	case "hPa"
		P = u.amb.P * 100;
	case "MPa"
		P = u.amb.P * 1e6;
	case "bar"
		P = u.amb.P * 1e5;
	case "psi"
		P = u.amb.P * 6894.757;
	case "atm"
		P = u.amb.P * 101325;
	case "mmHg"
		P = u.amb.P * 133.322;
	otherwise
		error("Pa, hPa, MPa, bar, psi, atm, mmHg 단위만 입력 가능");
end

% amb.T, K
switch unit.amb.T
	case "K"
		T = u.amb.T;
	case "°C"
		T = u.amb.T + 273.15;
	case "°F"
		T = (u.amb.T - 32) * 5/9 +273.15;
	case "C"
		T = u.amb.T + 273.15;
	case "F"
		T = (u.amb.T - 32) * 5/9 + 273.15;
	otherwise
		error("K, °C, °F, C, F 단위만 입력 가능")
end

% amb.g, m/s^2
switch unit.amb.g
	case "m/s^2"
		g = u.amb.g;
	case "cm/s^2"
		g = u.amb.g * 0.01;
	case "ft/s^2"
		g = u.amb.g * 0.3048;
	otherwise
		error("허용된 단위: m/s^2, cm/s^2, ft/s^2만 입력 가능");
end

%% 상태량 초기화
x.amb.P = P; % Pa
x.amb.T = T; % K
x.amb.g = g; % m/s^2

end 