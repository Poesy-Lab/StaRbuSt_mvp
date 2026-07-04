function [x] = Init_Feed(u, unit)
%Init_Feed  급기 라인(탱크-인젝터 배관) 설정 초기화
%   u.feed.mode = 0 (또는 필드 없음): 탱크-인젝터 직결 (기존 동작, 구버전 설정 호환)
%   u.feed.mode = 1: 급기 라인 모델 사용 (Feed_Line.m; CoolProp 물성 모델 필요)
x = struct();

% 구버전 설정 호환: feed 필드가 없으면 직결 모드
if ~isfield(u, 'feed') || ~isfield(u.feed, 'mode') || u.feed.mode == 0
    x.feed.mode = 0;
    return;
end
x.feed.mode = 1;

%% 입력값 변환
% 탱크 출구 입구손실 계수
if isfield(u.feed, 'K_entrance')
    x.feed.K_ent = u.feed.K_entrance;
else
    x.feed.K_ent = 0.5;
end

% 플렉시블 파이프
d_flex = len_convert(u.feed.flex.d, unit.feed.flex.d);
x.feed.flex.D = d_flex;
x.feed.flex.A = (pi/4) * d_flex^2;
x.feed.flex.L = len_convert(u.feed.flex.L, unit.feed.flex.L);
x.feed.flex.fmult = u.feed.flex.fmult;   % 주름관 마찰 배수 (매끈관=1)
x.feed.flex.K_bend = u.feed.flex.K_bend; % 벤드 부차손실

% 직관 (파이프1: 플렉시블-밸브, 파이프2: 밸브-인젝터)
d_pipe = len_convert(u.feed.pipe.d, unit.feed.pipe.d);
x.feed.pipe.D = d_pipe;
x.feed.pipe.A = (pi/4) * d_pipe^2;
x.feed.pipe.L1 = len_convert(u.feed.pipe.L1, unit.feed.pipe.L1);
x.feed.pipe.L2 = len_convert(u.feed.pipe.L2, unit.feed.pipe.L2);

% 볼밸브: 2상(플래싱) 유동에서는 하류 압력회복이 사라져 축소 보어가
% 오리피스처럼 동작 -> 보어 기준 무회복 K로 환산 (라인 유속 기준)
d_bore = len_convert(u.feed.valve.d_bore, unit.feed.valve.d_bore);
A_bore = (pi/4) * d_bore^2;
x.feed.valve.d_bore = d_bore;
x.feed.valve.Cd_bore = u.feed.valve.Cd_bore;
x.feed.valve.K = (x.feed.pipe.A / (u.feed.valve.Cd_bore * A_bore))^2 - 1;

end

function L = len_convert(val, unit_str)
switch unit_str
    case "m"
        L = val;
    case "mm"
        L = val * 1e-3;
    case "cm"
        L = val * 1e-2;
    case "in"
        L = val * 0.0254;
    otherwise
        error("허용된 단위: m, mm, cm, in만 입력 가능");
end
end
