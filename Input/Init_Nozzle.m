function [x_nozzle] = Init_Nozzle(u, unit) % 입력 변경
x_nozzle = struct(); % 로컬 구조체 초기화

%% 입력값 변환
% nozzle.Dt, m
switch unit.nozzle.Dt
	case "m"
		Dt = u.nozzle.Dt;
	case "mm"
		Dt = u.nozzle.Dt * 1e-3;
	case "cm"
		Dt = u.nozzle.Dt * 1e-2;
	case "in"
		Dt = u.nozzle.Dt * 0.0254;
	otherwise
		error("허용된 단위: m, mm, cm, in만 입력 가능");
end

if isfield(u.nozzle, 'De') % 노즐 출구 직경을 직접 설정한 경우
	switch unit.nozzle.De % nozzle.De, m
		case "m"
			De = u.nozzle.De;
		case "mm"
			De = u.nozzle.De * 1e-3;
		case "cm"
			De = u.nozzle.De * 1e-2;
		case "in"
			De = u.nozzle.De * 0.0254;
		otherwise
			error("허용된 단위: m, mm, cm, in만 입력 가능");
	end
	% 출구 직경으로 면적비 계산 (만약 eps가 없거나 다르면 업데이트)
	eps_calc = (De/Dt)^2;
	if ~isfield(u.nozzle, 'eps') || abs(u.nozzle.eps - eps_calc) > 1e-9 % 부동 소수점 비교 오차 고려
		 u.nozzle.eps = eps_calc; % u 구조체를 직접 수정하는 것은 바람직하지 않을 수 있음 -> 추후 검토 필요
	end
elseif isfield(u.nozzle, 'eps') % 노즐 면적 확장비로부터 면적 계산
	De = sqrt(u.nozzle.eps) * Dt;
else
    error("노즐 출구 직경(De) 또는 면적비(eps) 중 하나는 반드시 입력해야 합니다.");
end

% nozzle.Dc, m (노즐 수축부 입구 직경)
if isfield(u.nozzle, 'Dc')
    if isfield(unit.nozzle, 'Dc')
        switch unit.nozzle.Dc
            case "m"
                Dc_m = u.nozzle.Dc;
            case "mm"
                Dc_m = u.nozzle.Dc * 1e-3;
            case "cm"
                Dc_m = u.nozzle.Dc * 1e-2;
            case "in"
                Dc_m = u.nozzle.Dc * 0.0254;
            otherwise
                error("Init_Nozzle:InvalidUnitDc", "허용된 노즐 수축부 입구 직경 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.nozzle.Dc);
        end
    else
        warning('Init_Nozzle:MissingUnitDc', '노즐 수축부 입구 직경 단위 (unit.nozzle.Dc)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
        Dc_m = u.nozzle.Dc; % 기본 단위 m으로 가정
    end
else
    error('Init_Nozzle:MissingDc', '노즐 수축부 입구 직경 (u.nozzle.Dc)이(가) 입력되지 않았습니다.');
end

% nozzle.theta_c, radian (노즐 수축부 수축각)
if isfield(u.nozzle, 'theta_c')
    if isfield(unit.nozzle, 'theta_c')
        switch unit.nozzle.theta_c
            case "degree"
                theta_c_rad = u.nozzle.theta_c * pi/180;
            case "radian"
                theta_c_rad = u.nozzle.theta_c;
            otherwise
                error("Init_Nozzle:InvalidUnitThetaC", "허용된 노즐 수축각 단위: degree, radian만 입력 가능. 입력된 단위: %s", unit.nozzle.theta_c);
        end
    else
        warning('Init_Nozzle:MissingUnitThetaC', '노즐 수축각 단위 (unit.nozzle.theta_c)가 지정되지 않았습니다. 기본 단위인 radian으로 가정합니다.');
        theta_c_rad = u.nozzle.theta_c; % 기본 단위 radian으로 가정 (주의: 사용자가 degree로 입력했을 가능성 있음)
    end
else
    error('Init_Nozzle:MissingThetaC', '노즐 수축각 (u.nozzle.theta_c)이(가) 입력되지 않았습니다.');
end

switch unit.nozzle.alpha
	case "degree"
		alpha = u.nozzle.alpha * pi/180;
	case "radian"
		alpha = u.nozzle.alpha;
	otherwise
	    error("허용된 노즐 반각 단위: degree, radian"); % 에러 메시지 추가
end

if isfield(u.nozzle, 'theta_e')
	switch unit.nozzle.theta_e
		case "degree"
			theta_e = u.nozzle.theta_e * pi/180;
			beta = (alpha + theta_e) / 2;
		case "radian"
			theta_e = u.nozzle.theta_e;
			beta = (alpha + theta_e) / 2;
		otherwise
			error("허용된 단위: degree, radian 만 입력 가능")
	end
else
	beta = alpha;
end

%% 상태량 초기화
x_nozzle.nozzle.Dt = Dt; % m
x_nozzle.nozzle.De = De; % m
x_nozzle.nozzle.At = pi*(Dt/2)^2; % m^2, 목 면적 추가
x_nozzle.nozzle.Ae = pi*(De/2)^2; % m^2, 출구 면적 추가
x_nozzle.nozzle.eps = u.nozzle.eps; % Note: u.nozzle.eps might have been modified above
x_nozzle.nozzle.eta = u.nozzle.eta;
x_nozzle.nozzle.lambda = 1/2 * (1 + cos(beta));
x_nozzle.nozzle.Dc = Dc_m; % m, 노즐 수축부 입구 직경
x_nozzle.nozzle.theta_c = theta_c_rad; % radian, 노즐 수축부 수축각

% Calculate Nozzle Converging Section Volume (원뿔대 형상 가정)
V_conv = NaN; % Initialize
Rc = Dc_m / 2; % 수축부 입구 반경 (m)
Rt = Dt / 2;   % 노즐 목 반경 (m)

if theta_c_rad > 1e-9 && abs(Rc - Rt) > 1e-9 % theta_c가 0이 아니고, Rc와 Rt가 다를 때 (일반적인 경우)
    Lc_conv = (Rc - Rt) / tan(theta_c_rad); % 수축부 길이 (m)
    if Lc_conv > 0
        V_conv = (1/3) * pi * Lc_conv * (Rc^2 + Rc * Rt + Rt^2); % 원뿔대 부피 (m^3)
    else
        warning('Init_Nozzle:InvalidLcConv', '계산된 노즐 수축부 길이가 0 이하입니다 (Lc_conv = %.2e m). 부피를 계산할 수 없습니다.', Lc_conv);
    end
elseif abs(Rc - Rt) <= 1e-9 % Rc와 Rt가 거의 같으면 원통으로 간주 (이론상으론 길이 0)
    warning('Init_Nozzle:RcEqualsRt', '노즐 수축부 입구 반경과 목 반경이 거의 동일합니다 (Rc=%.2em, Rt=%.2em). 수축부 길이가 0으로 간주되어 부피는 0입니다.', Rc, Rt);
    V_conv = 0; % 또는 오류 처리
elseif theta_c_rad <= 1e-9 % 수축각이 0에 가까우면 길이 계산 불가
    warning('Init_Nozzle:ZeroThetaC', '노즐 수축각이 0에 가깝습니다 (theta_c = %.2e rad). 수축부 길이를 계산할 수 없어 부피 계산이 불가능합니다.', theta_c_rad);
end
x_nozzle.nozzle.V_conv = V_conv; % m^3, 노즐 수축부 부피

end 