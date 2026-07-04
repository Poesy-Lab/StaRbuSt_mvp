function Compare_2026_HotFire(config_base, save_png)
%Compare_2026_HotFire  2026 연소시험 실측 vs 시뮬레이션 겹침 비교
%   Compare_2026_HotFire()   % 기본: '2026_nova_line_hot'
%
%   실측: docs/시험 정보/2026 연소시험 데이터/26.07.03#1.lvm (2 kHz, 6채널)
%         채널/캘리브레이션은 Process_HotFire_2026.m 기준 (추력 kgf->N)
%   시뮬: Mat_Data/<config>/<config>_y.mat (Run_Config로 생성; 없으면 자동 실행)
%   정렬: 시험 점화(프리챔버압 > 3 bar g) <-> 시뮬 u.time.run
%   프로젝트 루트에서 실행하세요.

if nargin < 1 || isempty(config_base), config_base = '2026_nova_line_hot'; end
if nargin < 2 || isempty(save_png), save_png = true; end

%% 실측 데이터 로드
D = fullfile('docs', '시험 정보', '2026 연소시험 데이터');
raw = readmatrix(fullfile(D, '26.07.03#1.lvm'), 'FileType', 'text');
t_t  = raw(:, 1);
F_t  = movmean((6446.94865 * raw(:, 3) - 25.78494) * 9.80665, 200); % N
Ptk_t = movmean(6174.60242 * raw(:, 4) - 24.59134, 100) + 1.013;    % bar abs
Pc_t  = movmean(3118.71908 * raw(:, 5) - 12.4072, 100) + 1.013;     % bar abs (프리챔버)
i_ign = find(Pc_t > 3 + 1.013, 1);
tr_t = t_t - t_t(i_ign);

%% 시뮬레이션 이력 로드 (없으면 실행)
yfile = fullfile('Mat_Data', config_base, [config_base '_y.mat']);
if ~exist(yfile, 'file')
    fprintf('시뮬 이력이 없어 실행합니다: Run_Config(''%s'')\n', config_base);
    Run_Config(config_base);
end
S = load(yfile, 'y');
y = S.y;
cfg = load(fullfile('Config', [config_base '.mat']), 'u');
tr_s = y.time - cfg.u.time.run;

%% 겹침 플롯
fig = figure('Name', '2026 Hot-Fire Test vs Simulation', ...
             'Position', [100 100 900 850], 'Color', 'w');
tl = [-0.5, 5.5];

subplot(3, 1, 1);
plot(tr_t, F_t, 'k-', 'LineWidth', 1.5); hold on;
plot(tr_s, y.nozzle.F, 'r--', 'LineWidth', 1.8); hold off;
grid on; xlim(tl); ylabel('Thrust [N]');
legend('Test (measured)', 'Simulation', 'Location', 'northeast');
title(sprintf('2026 Hot-Fire Test #1 (07.03) vs Simulation (%s)', strrep(config_base, '_', '\_')));

subplot(3, 1, 2);
plot(tr_t, Pc_t, 'k-', 'LineWidth', 1.5); hold on;
plot(tr_s, y.comb.P / 1e5, 'r--', 'LineWidth', 1.8); hold off;
grid on; xlim(tl); ylabel('P_c [bar abs]');
legend('Test (pre-chamber)', 'Simulation', 'Location', 'northeast');

subplot(3, 1, 3);
plot(tr_t, Ptk_t, 'k-', 'LineWidth', 1.5); hold on;
plot(tr_s, y.tank.P / 1e5, 'r--', 'LineWidth', 1.8); hold off;
grid on; xlim(tl); ylabel('P_{tank} [bar abs]'); xlabel('Time since ignition [s]');
legend('Test (measured)', 'Simulation', 'Location', 'northeast');

%% 정량 지표 (준정상 창 0.5~2.0s + 총임펄스)
w_t = tr_t >= 0.5 & tr_t <= 2.0;
w_s = tr_s >= 0.5 & tr_s <= 2.0;
burn_t = Pc_t > 3 + 1.013;
I_t = trapz(t_t(burn_t), F_t(burn_t));
burn_s = tr_s > 0 & isfinite(y.nozzle.F(:))' & y.nozzle.F > 0;
I_s = trapz(y.time(burn_s), y.nozzle.F(burn_s));
fprintf('[%s] 준정상(0.5-2.0s) 평균: Pc 시험 %.1f / 시뮬 %.1f bar (%+.1f), F 시험 %.0f / 시뮬 %.0f N (%+.0f)\n', ...
    config_base, mean(Pc_t(w_t)), mean(y.comb.P(w_s))/1e5, mean(y.comb.P(w_s))/1e5 - mean(Pc_t(w_t)), ...
    mean(F_t(w_t)), mean(y.nozzle.F(w_s)), mean(y.nozzle.F(w_s)) - mean(F_t(w_t)));
fprintf('총임펄스: 시험 %.0f / 시뮬 %.0f N.s (%+.0f%%)\n', I_t, I_s, 100*(I_s - I_t)/I_t);

if save_png
    out = fullfile('TMS_Data', sprintf('Compare_2026_HotFire_%s.png', config_base));
    exportgraphics(fig, out, 'Resolution', 130);
    fprintf('그림 저장: %s\n', out);
end
end
