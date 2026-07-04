function Compare_2026_Spray(config_base, test_id, save_png)
%Compare_2026_Spray  2026 분무시험(N2O) 실측 vs 시뮬레이션 겹침 비교
%   Compare_2026_Spray()                              % 기본: '2026_nova_line_cold', Test 1
%   Compare_2026_Spray('2026_nova_line_cold', 2)      % Test 2와 비교
%
%   실측: docs/시험 정보/2026_연구부_수류시험_데이터/2026_test(.lvm|_2.lvm) (5 kHz, 2026 캘리)
%   시뮬: Mat_Data/<config>/<config>_y.mat (Run_Config로 생성; 없으면 자동 실행)
%   정렬: 시험 밸브 개방(P_inj 상승) <-> 시뮬 u.time.run (밸브 개방 기준 상대시간)
%   프로젝트 루트에서 실행하세요.

if nargin < 1 || isempty(config_base), config_base = '2026_nova_line_cold'; end
if nargin < 2 || isempty(test_id), test_id = 1; end
if nargin < 3 || isempty(save_png), save_png = true; end

%% 실측 데이터 로드 (2026 캘리브레이션, 게이지 -> 절대압)
D = fullfile('docs', '시험 정보', '2026_연구부_수류시험_데이터');
if test_id == 1
    lvm = '2026_test.lvm';
else
    lvm = '2026_test_2.lvm';
end
raw = readmatrix(fullfile(D, lvm), 'FileType', 'text');
t_t   = raw(:, 1);
Ptk_t = movmean(6174.602420 * raw(:, 2) - 24.591340, 2500) + 1.013; % bar abs
Pin_t = movmean(3118.719080 * raw(:, 3) - 12.407200, 2500) + 1.013; % bar abs
mass  = 3108.705160 * raw(:, 4) - 12.343940;                        % kg
mdot_t = movmean(-gradient(movmean(mass, 2500), t_t), 5000);        % kg/s
i_open = find(Pin_t > 3 + 1.013, 1); % 밸브 개방 감지
tr_t = t_t - t_t(i_open);

%% 시뮬레이션 이력 로드 (없으면 실행)
yfile = fullfile('Mat_Data', config_base, [config_base '_y.mat']);
if ~exist(yfile, 'file')
    fprintf('시뮬 이력이 없어 실행합니다: Run_Config(''%s'')\n', config_base);
    Run_Config(config_base);
end
S = load(yfile, 'y');
y = S.y;
cfg = load(fullfile('Config', [config_base '.mat']), 'u');
t_run = cfg.u.time.run; % 밸브 개방 시각 (시뮬)
tr_s = y.time - t_run;

%% 겹침 플롯
fig = figure('Name', sprintf('2026 Spray Test %d vs Simulation', test_id), ...
             'Position', [100 100 900 850], 'Color', 'w');
tl = [-0.5, min(max(tr_t), max(tr_s)) + 0.3];

subplot(3, 1, 1);
plot(tr_t, mdot_t, 'k-', 'LineWidth', 1.8); hold on;
plot(tr_s, y.inj.mdot, 'r--', 'LineWidth', 1.8); hold off;
grid on; xlim(tl); ylabel('mdot [kg/s]');
legend(sprintf('Test %d (measured)', test_id), 'Simulation', 'Location', 'northeast');
title(sprintf('2026 N2O Spray Test %d vs Simulation (%s)', test_id, strrep(config_base, '_', '\_')));

subplot(3, 1, 2);
plot(tr_t, Ptk_t, 'k-', 'LineWidth', 1.8); hold on;
plot(tr_s, y.tank.P / 1e5, 'r--', 'LineWidth', 1.8); hold off;
grid on; xlim(tl); ylabel('P_{tank} [bar abs]');
legend('Test (measured)', 'Simulation', 'Location', 'northeast');

subplot(3, 1, 3);
plot(tr_t, Pin_t, 'k-', 'LineWidth', 1.8); hold on;
plot(tr_s, y.feed.P_out / 1e5, 'r--', 'LineWidth', 1.8); hold off;
grid on; xlim(tl); ylabel('P_{inj} [bar abs]'); xlabel('Time since valve open [s]');
legend('Test (measured)', 'Simulation (line outlet)', 'Location', 'northeast');

%% 정량 지표 (액상 준정상 창)
liq = ~isnan(y.inj.x1_in(:)) & tr_s(:) > 0;
t_end = min(3.4, max(tr_s(liq)));
tq = (0.3:0.05:t_end)';
Ps = interp1(tr_s, y.feed.P_out / 1e5, tq);  Ms = interp1(tr_s, y.inj.mdot, tq);
Pq = interp1(tr_t, Pin_t, tq);               Mq = interp1(tr_t, mdot_t, tq);
fprintf('[Test %d vs %s] 액상 창(0.3~%.1fs): P_inj RMSE %.2f bar, mdot RMSE %.4f kg/s (bias %+.4f)\n', ...
    test_id, config_base, t_end, sqrt(mean((Ps - Pq).^2, 'omitnan')), ...
    sqrt(mean((Ms - Mq).^2, 'omitnan')), mean(Ms - Mq, 'omitnan'));

if save_png
    out = fullfile('TMS_Data', sprintf('Compare_2026_Spray_Test%d_%s.png', test_id, config_base));
    exportgraphics(fig, out, 'Resolution', 130);
    fprintf('그림 저장: %s\n', out);
end
end
