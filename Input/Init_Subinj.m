function [x] = Init_Subinj(u, unit)
x = struct(); % 반환 구조체 초기화

% 서브 인젝터 모드 확인
if ~isfield(u, 'subinj') || ~isfield(u.subinj, 'mode') || u.subinj.mode == 0
    x.subinj = struct(); % 필드를 생성하지만 비워둠
    return;
end

%% 입력값 변환
if isfield(u.subinj, 'A') % 서브 인젝터 면적을 직접 설정한 경우
	switch unit.subinj.A
		case "m^2"
			A = u.subinj.A;
		case "mm^2"
			A = u.subinj.A * 1e-6;
		case "cm^2"
			A = u.subinj.A * 1e-4;
		case "in^2"
			A = u.subinj.A * 0.00064516;
		otherwise
			error("허용된 단위: m^2, mm^2, cm^2, in^2만 입력 가능");
	end
elseif isfield(u.subinj, 'd') % 서브 인젝터의 직경으로부터 면적 계산
	d_m = NaN; % Initialize d_m for single orifice diameter in meters
	if isfield(unit, 'subinj') && isfield(unit.subinj, 'd') % 단위 정보가 있는지 확인
		switch unit.subinj.d
			case "m"
				d_m = u.subinj.d;
			case "mm"
				d_m = u.subinj.d * 1e-3;
			case "cm"
				d_m = u.subinj.d * 1e-2;
			case "in"
				d_m = u.subinj.d * 0.0254;
			otherwise
				error("Init_Subinj:InvalidUnitD", "허용된 서브 인젝터 직경 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.subinj.d);
		end
	else
		warning('Init_Subinj:MissingUnitD', '서브 인젝터 직경 단위 (unit.subinj.d)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
		d_m = u.subinj.d; % 단위 정보가 없으면 기본 단위(m)로 가정
	end

	if isnan(d_m) || d_m <= 0
		error('Init_Subinj:InvalidOrificeDiameter', '계산된 서브 인젝터 오리피스 직경이 유효하지 않습니다 (d_m = %.2e m).', d_m);
	end

	A = (pi/4) * (d_m)^2; % 개별 오리피스 단면적 계산 (m^2) using d_m
else
	error("서브 인젝터 면적을 직접 설정하거나 직경을 설정해야 합니다.");
end

% subinj.model_LiqFeed - Store the string
if isfield(u.subinj, 'model_LiqFeed')
    model_LiqFeed_str = string(u.subinj.model_LiqFeed); % Ensure string type
    % Add basic validation if needed (e.g., check for known keywords)
    if ~(contains(model_LiqFeed_str, "NHNE", "IgnoreCase", true) || contains(model_LiqFeed_str, "CdA", "IgnoreCase", true))
        warning('Init_Subinj:UnknownLiqModel', 'Unknown liquid feed model: %s', model_LiqFeed_str);
    end
else
    error('Missing input: u.subinj.model_LiqFeed is required.'); % Require the input
end

% subinj.model_VapFeed - Store the string
if isfield(u.subinj, 'model_VapFeed')
    model_VapFeed_str = string(u.subinj.model_VapFeed); % Ensure string type
    % Add basic validation if needed
    if ~(contains(model_VapFeed_str, "ICF", "IgnoreCase", true) || contains(model_VapFeed_str, "CdA", "IgnoreCase", true))
         warning('Init_Subinj:UnknownVapModel', 'Unknown vapor feed model: %s', model_VapFeed_str);
    end
else
     error('Missing input: u.subinj.model_VapFeed is required.'); % Require the input
end

% subinj.L, m (인젝터 플레이트 두께)
if isfield(u.subinj, 'L')
    if isfield(unit, 'subinj') && isfield(unit.subinj, 'L') % 단위 정보가 있는지 확인
        switch unit.subinj.L
            case "m"
                L_m = u.subinj.L;
            case "mm"
                L_m = u.subinj.L * 1e-3;
            case "cm"
                L_m = u.subinj.L * 1e-2;
            case "in"
                L_m = u.subinj.L * 0.0254;
            otherwise
                error("Init_Subinj:InvalidUnitL", "허용된 서브 인젝터 플레이트 두께 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.subinj.L);
        end
    else
        warning('Init_Subinj:MissingUnitL', '서브 인젝터 플레이트 두께 단위 (unit.subinj.L)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
        L_m = u.subinj.L; % 단위 정보가 없으면 기본 단위(m)로 가정
    end
else
    error('Init_Subinj:MissingL', '서브 인젝터 플레이트 두께 (u.subinj.L)이(가) 입력되지 않았습니다.');
end

%% 상태량 초기화
x.subinj.A = u.subinj.n * A; % 총 서브 인젝터 면적 (m^2)
x.subinj.Cd = u.subinj.Cd; % 토출 계수
x.subinj.L = L_m; % 서브 인젝터 플레이트 두께 (m)
x.subinj.d = d_m; % 단일 서브 인젝터 오리피스 직경 (m)
x.subinj.model_LiqFeed = model_LiqFeed_str; % 액상 공급 모델 이름 (문자열)
x.subinj.model_VapFeed = model_VapFeed_str; % 기상 공급 모델 이름 (문자열)

end
