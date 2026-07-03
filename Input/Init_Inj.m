function [x] = Init_Inj(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환
if isfield(u.inj, 'A') % 인젝터 면적을 직접 설정한 경우
	switch unit.inj.A
		case "m^2"
			A = u.inj.A;
		case "mm^2"
			A = u.inj.A * 1e-6;
		case "cm^2"
			A = u.inj.A * 1e-4;
		case "in^2"
			A = u.inj.A * 0.00064516;
		otherwise
			error("허용된 단위: m^2, mm^2, cm^2, in^2만 입력 가능");
	end
elseif isfield(u.inj, 'd') % 인젝터의 직경으로부터 면적 계산
	d_m = NaN; % Initialize d_m for single orifice diameter in meters
	if isfield(unit, 'inj') && isfield(unit.inj, 'd') % 단위 정보가 있는지 확인
		switch unit.inj.d
			case "m"
				d_m = u.inj.d;
			case "mm"
				d_m = u.inj.d * 1e-3;
			case "cm"
				d_m = u.inj.d * 1e-2;
			case "in"
				d_m = u.inj.d * 0.0254;
			otherwise
				error("Init_Inj:InvalidUnitD", "허용된 인젝터 직경 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.inj.d);
		end
	else
		warning('Init_Inj:MissingUnitD', '인젝터 직경 단위 (unit.inj.d)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
		d_m = u.inj.d; % 단위 정보가 없으면 기본 단위(m)로 가정
	end

	if isnan(d_m) || d_m <= 0
		error('Init_Inj:InvalidOrificeDiameter', '계산된 인젝터 오리피스 직경이 유효하지 않습니다 (d_m = %.2e m).', d_m);
	end

	A = (pi/4) * (d_m)^2; % 개별 오리피스 단면적 계산 (m^2) using d_m
else
	error("인젝터 면적을 직접 설정하거나 직경을 설정해야 합니다.");
end

% inj.model_LiqFeed - Store the string
if isfield(u.inj, 'model_LiqFeed')
    model_LiqFeed_str = string(u.inj.model_LiqFeed); % Ensure string type
    % Add basic validation if needed (e.g., check for known keywords)
    if ~(contains(model_LiqFeed_str, "NHNE", "IgnoreCase", true) || contains(model_LiqFeed_str, "CdA", "IgnoreCase", true))
        warning('Init_Inj:UnknownLiqModel', 'Unknown liquid feed model: %s', model_LiqFeed_str);
    end
else
    error('Missing input: u.inj.model_LiqFeed is required.'); % Require the input
end

% inj.model_VapFeed - Store the string
if isfield(u.inj, 'model_VapFeed')
    model_VapFeed_str = string(u.inj.model_VapFeed); % Ensure string type
    % Add basic validation if needed
    if ~(contains(model_VapFeed_str, "ICF", "IgnoreCase", true) || contains(model_VapFeed_str, "CdA", "IgnoreCase", true))
         warning('Init_Inj:UnknownVapModel', 'Unknown vapor feed model: %s', model_VapFeed_str);
    end
else
     error('Missing input: u.inj.model_VapFeed is required.'); % Require the input
end

% inj.L, m (인젝터 플레이트 두께)
if isfield(u.inj, 'L')
    if isfield(unit, 'inj') && isfield(unit.inj, 'L') % 단위 정보가 있는지 확인
        switch unit.inj.L
            case "m"
                L_m = u.inj.L;
            case "mm"
                L_m = u.inj.L * 1e-3;
            case "cm"
                L_m = u.inj.L * 1e-2;
            case "in"
                L_m = u.inj.L * 0.0254;
            otherwise
                error("Init_Inj:InvalidUnitL", "허용된 인젝터 플레이트 두께 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.inj.L);
        end
    else
        warning('Init_Inj:MissingUnitL', '인젝터 플레이트 두께 단위 (unit.inj.L)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
        L_m = u.inj.L; % 단위 정보가 없으면 기본 단위(m)로 가정
    end
else
    error('Init_Inj:MissingL', '인젝터 플레이트 두께 (u.inj.L)이(가) 입력되지 않았습니다.');
end

%% 상태량 초기화
x.inj.A = u.inj.n * A; % 총 인젝터 면적 (m^2)
x.inj.Cd = u.inj.Cd; % 토출 계수
x.inj.L = L_m; % 인젝터 플레이트 두께 (m)
x.inj.d = d_m; % 단일 인젝터 오리피스 직경 (m)
x.inj.model_LiqFeed = model_LiqFeed_str; % 액상 공급 모델 이름 (문자열)
x.inj.model_VapFeed = model_VapFeed_str; % 기상 공급 모델 이름 (문자열)

end 