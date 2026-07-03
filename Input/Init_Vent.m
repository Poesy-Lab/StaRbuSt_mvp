function [x] = Init_Vent(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환
if isfield(u.vent, 'A') % 벤트 포트 면적을 직접 설정한 경우
	switch unit.vent.A
		case "m^2"
			A = u.vent.A;
		case "mm^2"
			A = u.vent.A * 1e-6;
		case "cm^2"
			A = u.vent.A * 1e-4;
		case "in^2"
			A = u.vent.A * 0.00064516;
		otherwise
			error("허용된 단위: m^2, mm^2, cm^2, in^2만 입력 가능");
	end
elseif isfield(u.vent, 'd') % 벤트 포트의 직경으로부터 면적 계산
	switch unit.vent.d
		case "m"
			d = u.vent.d;
		case "mm"
			d = u.vent.d * 1e-3;
		case "cm"
			d = u.vent.d * 1e-2;
		case "in"
			d = u.vent.d * 0.0254;
		otherwise
			error("허용된 단위: m, mm, cm, in만 입력 가능");
	end
	A = (pi/4)*(d)^2; % 원형 벤트 포트 면적 계산 (m^2)
else
	error("벤트 포트 면적을 직접 설정하거나 직경을 설정해야 합니다.");
end

% vent.model - Store the model string directly
model_str = string(u.vent.model); % Ensure it's a string type

% Basic validation: Check if the input string contains known keywords
if ~(contains(model_str, "ICF", "IgnoreCase", true) || contains(model_str, "CdA", "IgnoreCase", true))
    warning('Init_Vent:UnknownModel', 'Unknown vent model string: "%s". Ensure PreFeed/other functions handle this.', model_str);
    % Keep the original string, let downstream functions decide behavior
end

%% 상태량 초기화
x.vent.A = A; % 벤트포트 면적 (m^2)
x.vent.model = model_str; % 벤트포트 해석 모델 문자열 ("ICF" 또는 "CdA" 포함 예상)
x.vent.Cd = u.vent.Cd; % 토출계수
x.vent.mode = u.vent.mode; % 0: 벤트포트 없음, 1: 벤트포트 있음

end 