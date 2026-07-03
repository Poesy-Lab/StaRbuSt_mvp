%% Compare_EOS_CoolProp.m
%  인하우스 HelmholtzEOS(N2O) vs CoolProp(N2O_CoolProp) 물성 대조 스크립트
%
%  실행: 프로젝트 루트에서
%    addpath(genpath('Props')); Compare_EOS_CoolProp
%  요구: MATLAB pyenv에 CoolProp 설치된 파이썬 연결 (CEA와 동일 경로)
%
%  두 모델은 같은 Lemmon-Span(2006) 상관식이므로 상대오차가 ~0.1% 수준이어야 정상.
%  h/s 절대값은 기준상태(영점)가 달라 직접 비교하지 않고, 기준 무관량인
%  잠열(L = h_v - h_l)로 엔탈피 일관성을 비교한다.

clc;
inh = N2O();
cpm = N2O_CoolProp();

Ts = [250 270 285 300]; % K

fprintf('=== 포화 물성 대조 (인하우스 vs CoolProp, 괄호는 상대오차) ===\n');
for k = 1:length(Ts)
    T = Ts(k);
    [rl_i, rv_i] = inh.satDensity(T);
    [rl_c, rv_c] = cpm.satDensity(T);

    Si = inh.GetProps(T, 0.5*(rl_i + rv_i)); % 포화 분기 -> Psat
    Sc = cpm.GetProps(T, 0.5*(rl_c + rv_c));

    Li = inh.GetProps(T, rl_i, 0); Vi = inh.GetProps(T, rv_i, 2);
    Lc = cpm.GetProps(T, rl_c, 0); Vc = cpm.GetProps(T, rv_c, 2);

    lat_i = Vi.h - Li.h; % 잠열 (기준상태 무관)
    lat_c = Vc.h - Lc.h;

    fprintf('T = %5.1f K\n', T);
    fprintf('  Psat : %11.4e vs %11.4e Pa   (%.4f %%)\n', Si.P, Sc.P, 100*rel(Si.P, Sc.P));
    fprintf('  rho_l: %11.2f vs %11.2f      (%.4f %%)\n', rl_i, rl_c, 100*rel(rl_i, rl_c));
    fprintf('  rho_v: %11.3f vs %11.3f      (%.4f %%)\n', rv_i, rv_c, 100*rel(rv_i, rv_c));
    fprintf('  c_l  : %11.2f vs %11.2f m/s  (%.4f %%)\n', Li.c, Lc.c, 100*rel(Li.c, Lc.c));
    fprintf('  c_v  : %11.2f vs %11.2f m/s  (%.4f %%)\n', Vi.c, Vc.c, 100*rel(Vi.c, Vc.c));
    fprintf('  cp_l : %11.1f vs %11.1f      (%.4f %%)\n', Li.cp, Lc.cp, 100*rel(Li.cp, Lc.cp));
    fprintf('  잠열 : %11.1f vs %11.1f J/kg (%.4f %%)\n', lat_i, lat_c, 100*rel(lat_i, lat_c));
end

fprintf('\n=== CoolProp 직접 플래시 스모크 테스트 ===\n');
T1 = 277.65; % 2026 수류시험 탱크 온도 (4.5 degC)
[rl_c, ~] = cpm.satDensity(T1);
up = cpm.GetProps(T1, rl_c, 0); % 포화액 상류 상태

ps = cpm.GetPropsPS(1e5, up.s); % 1 bar까지 등엔트로피 팽창
fprintf('P-s 플래시 (%.2f K 포화액 -> 1 bar): X = %.3f (기대 ~0.37), rho = %.2f (기대 ~7.9), state = %d\n', ...
    T1, ps.X, ps.rho, ps.state);

dh = cpm.GetPropsDH(up.rho, up.h); % 자기 자신 복원 테스트
fprintf('rho-h 플래시 (포화액 복원): T = %.3f K (기대 %.3f), P = %.4e Pa\n', dh.T, T1, dh.P);

ps_fail = cpm.GetPropsPS(1e3, up.s); % 삼중점 이하 -> 실패가 정상 (state -1, 예외 없음)
fprintf('영역 밖 P-s 플래시 (0.01 bar): state = %d (기대 -1, 예외 없이 반환)\n', ps_fail.state);

function r = rel(a, b)
    r = abs(a - b) / max(abs(a), eps);
end
