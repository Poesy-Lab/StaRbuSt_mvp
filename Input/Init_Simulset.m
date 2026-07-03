function [x_simulset] = Init_Simulset(u, unit) % unit은 사용되지 않지만 통일성을 위해 유지
%% 입력값 확인
x_simulset = struct(); % 로컬 구조체 초기화

local_mode = -1; % 로컬 변수 초기화
switch u.test.mode
    case 1 % 연소 시험
        local_mode = 1;
    case 2 % 분무 시험
        local_mode = 2;
    otherwise
        error("허용된 시험 모드(u.test.mode)는 1(연소 시험) 또는 2(분무 시험)입니다.");
end

%% 상태량 초기화
x_simulset.test.mode = local_mode;

end 