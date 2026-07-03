function [x] = Init_Fuel(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환
% fuel.card
switch u.fuel.card
	case 'HDPE'
		card = ['fuel (CH2)x(cr) C 1.0 H 2.0 wt%=100.0', newline, ...
		'h,cal = -6188.6 t(k) = 298.15 rho = 0.935']; % h: cal/mol, rho: g/cm^3
		default_rho_g_cm3 = 0.935;
	case 'HTPB'
		card = ['fuel R-45(HTPB FROM_RPL_DATA) C 7.3165 H 10.3360 O 0.1063    wt%=100.00', newline, ...
		'h,cal= 1200.0 t(k)=298.15 rho=0.9220']; % h: cal/mol, rho: g/cm^3
		default_rho_g_cm3 = 0.9220;
    case 'Paraffin' % 추가된 케이스
        % Using C12H24 surrogate for paraffin: Hf = –92 200 cal/mol at 298 K, rho ≈ 0.900 g/cm³
        card = ['fuel C12H24(cr) C 12.0 H 24.0 wt%=100.00', newline, ...
                'h,cal = -92200.0 t(k) = 298.15 rho = 0.900']; % surrogate model
        default_rho_g_cm3 = 0.900;
	otherwise
		error("허용 추진제: HDPE, HTPB, Paraffin 만 입력 가능") % 오류 메시지 업데이트
end

% fuel.rho, kg/m³
if isfield(u.fuel, 'rho') % 사용자가 밀도를 입력한 경우
	switch unit.fuel.rho
		case "kg/m^3"
			rho = u.fuel.rho;
		case "g/cm^3"
			rho = u.fuel.rho * 1e3;
		case "lb/ft^3"
			rho = u.fuel.rho * 16.0185;
		otherwise
			error("허용된 단위: kg/m^3, g/cm^3, lb/ft^3만 입력 가능");
	end
else % 사용자가 밀도를 입력하지 않은 경우, card의 기본 밀도 사용
	rho = default_rho_g_cm3 * 1e3; % g/cm^3 -> kg/m^3
end

% fuel.R, m
switch unit.fuel.R
	case "m"
		R = u.fuel.R;
	case "mm"
		R = u.fuel.R * 1e-3;
	case "cm"
		R = u.fuel.R * 1e-2;
	case "in"
		R = u.fuel.R * 0.0254;
	otherwise
		error("허용된 단위: m, mm, cm, in만 입력 가능");
end

% fuel.R_out, m (Outer Radius)
if isfield(u.fuel, 'R_out')
    switch unit.fuel.R_out
        case "m"
            R_out = u.fuel.R_out;
        case "mm"
            R_out = u.fuel.R_out * 1e-3;
        case "cm"
            R_out = u.fuel.R_out * 1e-2;
        case "in"
            R_out = u.fuel.R_out * 0.0254;
        otherwise
            error("허용된 외경 단위: m, mm, cm, in만 입력 가능");
    end
    % Validate R_out >= R
    if R_out < R
        error('Init_Fuel:InvalidRadius', 'Outer radius (R_out=%.4f m) must be greater than or equal to inner radius (R=%.4f m).', R_out, R);
    end
else
    error('Init_Fuel:MissingOuterRadius', 'Outer radius (u.fuel.R_out) must be specified.');
end

% fuel.L, m
switch unit.fuel.L
	case "m"
		L = u.fuel.L;
	case "mm"
		L = u.fuel.L * 1e-3;
	case "cm"
		L = u.fuel.L * 1e-2;
	case "in"
		L = u.fuel.L * 0.0254;
	otherwise
		error("허용된 단위: m, mm, cm, in만 입력 가능");
end

% fuel.model
if isfield(u.fuel, 'model')
    model_str = string(u.fuel.model); % Ensure string type
    % Basic validation (currently only checks for "aGn")
    if ~contains(model_str, "aGn", "IgnoreCase", true)
        warning('Init_Fuel:UnknownModel', 'Unknown fuel model specified: "%s". Defaulting to "aGn".', model_str);
        model_str = "aGn"; % Default to aGn if unknown
    end
else
    warning('Init_Fuel:NoModel', 'Fuel regression model not specified (u.fuel.model). Defaulting to "aGn".');
    model_str = "aGn"; % Default to aGn if not specified
end

%% 상태량 초기화
x.fuel.Ap = pi * (R)^2; % m^2, 초기 포트 단면적
x.fuel.Ab = 2 * pi * R * L; % m^2, 초기 연소 표면적
x.fuel.R = R; % m, 현재 포트 반경 (초기값)
x.fuel.rho = rho; % kg/m^3, 연료 밀도
x.fuel.N = u.fuel.N; % 포트 개수
x.fuel.a = u.fuel.a; % 연소율 계수 a
x.fuel.n = u.fuel.n; % 연소율 지수 n
x.fuel.card = card; % CEA 카드 문자열
x.fuel.model = model_str; % 사용할 후퇴율 모델 이름 ("aGn" 등)
x.fuel.R_out = R_out; % m, 그레인 외경 추가
x.fuel.L = L;      % m, 그레인 길이 추가

end 