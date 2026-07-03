function [x] = Init_Time(u, unit)
x = struct(); % 반환 구조체 초기화

%% 입력값 변환 (모든 시간을 초 단위로 변환)

% 시작 시간 (start)
switch unit.time.start
    case "s"
        t_start = u.time.start;
    case "ms"
        t_start = u.time.start * 1e-3;
    case "min"
        t_start = u.time.start * 60;
    case "hr"
        t_start = u.time.start * 3600;
    otherwise
        error("허용된 시작 시간 단위: s, ms, min, hr");
end

% 연소 시간 (run)
switch unit.time.run
    case "s"
        t_run = u.time.run;
    case "ms"
        t_run = u.time.run * 1e-3;
    case "min"
        t_run = u.time.run * 60;
    case "hr"
        t_run = u.time.run * 3600;
    otherwise
        error("허용된 연소 시간 단위: s, ms, min, hr");
end

% 종료 시간 (stop)
switch unit.time.stop
    case "s"
        t_stop = u.time.stop;
    case "ms"
        t_stop = u.time.stop * 1e-3;
    case "min"
        t_stop = u.time.stop * 60;
    case "hr"
        t_stop = u.time.stop * 3600;
    otherwise
        error("허용된 종료 시간 단위: s, ms, min, hr");
end

% 시간 간격 (dt)
switch unit.time.dt
    case "s"
        dt = u.time.dt;
    case "ms"
        dt = u.time.dt * 1e-3;
    case "min"
        dt = u.time.dt * 60;
    case "hr"
        dt = u.time.dt * 3600;
    otherwise
        error("허용된 시간 간격 단위: s, ms, min, hr");
end

%% 상태량 초기화
x.time.start = t_start; % s
x.time.run = t_run;     % s
x.time.stop = t_stop;   % s
x.time.dt = dt;         % s
x.time.t = t_start:dt:t_stop; % 시뮬레이션 시간 벡터 (s)
x.time.N = length(x.time.t); % 시간 스텝 수

end 