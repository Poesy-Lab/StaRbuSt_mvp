%% Process_HotFire_2026.m
%  2026 연소시험 LVM 데이터 가공 및 분석
%  - 5채널 캘리브레이션 적용
%  - 추력·질량·압력 시계열 분석
%  - 성능 파라미터 산출 (총 임펄스, 비추력, O/F 등)
%  - 보고서용 영어 그래프 생성
%
%  채널 배치 (LVM 파일 물리 분석 확정 — 사용자 나열 순서와 col2/col3 반전):
%    col1 = 시간 [s]
%    col2 = 산화제 탱크 질량 (로드셀)  → [kg]   (사용자 목록상 2번째)
%    col3 = 추력 (로드셀)              → [N]    (사용자 목록상 1번째)
%    col4 = 산화제 탱크 압력 (100bar)  → [bar]
%    col5 = 프리챔버 압력 (50bar)      → [bar]
%    col6 = 포스트챔버 압력 (50bar)    → [bar]
%
%  입력: 26.07.03#1.lvm  (2kHz, 232100 samples, 116.05s)
%  출력: 보고서용 PNG 5장 (300 dpi)
%
%  ★ 캘리브레이션: 2025 참조값 사용 — 실제 교정파일 수신 후 갱신 필요
%    특히 질량 채널은 0.46 kg 범위만 관측 (설계 1.1 kg 대비 과소)
%    → 로드셀 감도 또는 캘리브레이션 계수 확인 필요

clear; clc; close all;

%% ========== 1. Configuration (★ UPDATE AFTER RECEIVING DATA) ==========

% ── 데이터 파일 경로 ──
DATA_FILE = '26.07.03#1.lvm';           % ★ 실제 파일명으로 변경

% ── 채널 인덱스 (LVM 열 번호) ──
% ★ 주의: col2=질량, col3=추력 (사용자 나열 순서와 반전 확인됨)
CH.time      = 1;    % 시간 [s]
CH.mass      = 2;    % 탱크 질량 로드셀 [V]  ← col2
CH.thrust    = 3;    % 추력 로드셀 [V]       ← col3
CH.P_tank    = 4;    % 산화제 탱크 압력 [V]
CH.Pc_pre    = 5;    % 프리챔버 압력 [V]
CH.Pc_post   = 6;    % 포스트챔버 압력 [V]

% ── 캘리브레이션 계수: phys = a * V + b  (Cali_2026.xlsx 기준) ──
cal.thrust.a   = 6446.94865; cal.thrust.b  = -25.78494;  % 로드셀1 → [kgf]
cal.thrust.unit_kgf = true;   % true: 출력이 kgf → N 변환 필요

cal.mass.a     = 6250.0;     cal.mass.b    = -25.0;      % 로드셀2 → [kgf] ≈ [kg]

cal.P_tank.a   = 6174.60242; cal.P_tank.b  = -24.59134;  % 압력센서1 (100bar) → [bar]
cal.Pc_pre.a   = 3118.71908; cal.Pc_pre.b  = -12.4072;   % 압력센서4 (50bar) → [bar]
cal.Pc_post.a  = 3090.80188; cal.Pc_post.b = -12.37548;  % 압력센서5 (50bar) → [bar]

% ── 샘플링 ──
dt = 0.0005;                % [s] (2 kHz — LVM 실측 확인)
fs = 1 / dt;

% ── 필터링 윈도우 (2 kHz 기준) ──
N_smooth_P     = 100;       % 압력 스무딩 (0.05s)
N_smooth_mass  = 1000;      % 질량 스무딩 (0.5s)
N_smooth_mdot  = 2000;      % 유량 추가 스무딩 (1.0s)
N_smooth_F     = 200;       % 추력 스무딩 (0.1s)

% ── 연소 판별 ──
Pc_threshold   = 3.0;       % 연소 시작 판별 임계값 [bar gauge]

% ── 시간 윈도우 ──
T_WIN = [-1, 9];            % 플롯 시간 범위 [s] (점화 전 1초 ~ 9초)

% ── 모터 설계 파라미터 (성능 계산용) ──
MOTOR.m_fuel_initial = 0.171;   % 연료 초기 질량 [kg] (★ 실측값으로 갱신)
MOTOR.P_amb          = 1.01325; % 대기압 [bar]

% ── 시험 정보 ──
TEST_DATE = '2026.07.03';       % 시험 일자
TEST_NAME = 'Hot-Fire Test #1'; % 시험 명칭

%% ========== 2. Data Loading ==========
fprintf('Loading data: %s\n', DATA_FILE);
raw = readmatrix(DATA_FILE, 'FileType', 'text');
fprintf('  %d samples loaded (%.1f s at %d Hz)\n', ...
    size(raw,1), size(raw,1)*dt, fs);

%% ========== 3. Calibration ==========
t_raw    = raw(:, CH.time);
F_raw_V  = raw(:, CH.thrust);
m_raw_V  = raw(:, CH.mass);
Pt_raw_V = raw(:, CH.P_tank);
Ppre_V   = raw(:, CH.Pc_pre);
Ppost_V  = raw(:, CH.Pc_post);

% 물리량 변환
F_kgf   = cal.thrust.a  * F_raw_V  + cal.thrust.b;
mass_kg = cal.mass.a     * m_raw_V  + cal.mass.b;
P_tank  = cal.P_tank.a   * Pt_raw_V + cal.P_tank.b;
Pc_pre  = cal.Pc_pre.a   * Ppre_V   + cal.Pc_pre.b;
Pc_post = cal.Pc_post.a  * Ppost_V  + cal.Pc_post.b;

% 추력: kgf → N (필요 시)
if cal.thrust.unit_kgf
    F_raw_N = F_kgf * 9.80665;
else
    F_raw_N = F_kgf;   % 이미 N 단위
end

%% ========== 4. Filtering ==========
% 압력
P_tank_f  = movmean(P_tank,  N_smooth_P);
Pc_pre_f  = movmean(Pc_pre,  N_smooth_P);
Pc_post_f = movmean(Pc_post, N_smooth_P);

% 추력: 테어 보정 + 스무딩
N_tare = min(1000, length(F_raw_N));   % 테어: 첫 0.2s
F_tare = mean(F_raw_N(1:N_tare));
F_N    = movmean(F_raw_N - F_tare, N_smooth_F);

% 질량: 스무딩 + 유량 계산
mass_f = movmean(mass_kg, N_smooth_mass);
dmdt   = gradient(mass_f, dt);
mdot   = movmean(-dmdt, N_smooth_mdot);   % 질량 감소 → 유량 양수

%% ========== 5. Time Alignment (t=0 at ignition) ==========
% 점화 판별: Pc_post가 임계값을 처음 초과하는 시점
idx_ign = find(Pc_post_f > Pc_threshold, 1, 'first');
if isempty(idx_ign)
    warning('Ignition not detected (Pc_post never exceeds %.1f bar). Using t=0 as-is.', Pc_threshold);
    idx_ign = 1;
end
t = t_raw - t_raw(idx_ign);   % 점화 = t=0

fprintf('  Ignition detected at raw t = %.3f s (index %d)\n', t_raw(idx_ign), idx_ign);

%% ========== 6. Oxidizer Fill Mass ==========
% 점화 직전 질량을 기준으로 충전 잔량 계산
mass_ref   = mass_f(idx_ign);
mass_fill  = mass_f - min(mass_f);        % 잔량: 충전량 → 0

% 산화제 토출 질량
dm_ox_loadcell = mass_ref - min(mass_f);  % 로드셀 직접 측정
dm_ox_integral = trapz(t_raw, mdot);      % mdot 적분

%% ========== 7. Burn Time / Operating Time Detection ==========
% Burn Time:      점화(t=0) → 최대 추력의 5% 이하 도달
% Operating Time: 점화(t=0) → 추력 ≈ 0 (max(1% peak, 10 N) 이하)

F_max = max(F_N);
[~, idx_peak] = max(F_N);

% --- Burn Time ---
thresh_burn = 0.05 * F_max;
idx_burn_end = idx_peak + find(F_N(idx_peak:end) < thresh_burn, 1, 'first') - 1;
if isempty(idx_burn_end), idx_burn_end = length(t); end
burn_time = t(idx_burn_end) - t(idx_ign);

% --- Operating Time ---
thresh_op = max(0.01 * F_max, 10);
idx_op_end = idx_peak + find(F_N(idx_peak:end) < thresh_op, 1, 'first') - 1;
if isempty(idx_op_end), idx_op_end = length(t); end
operating_time = t(idx_op_end) - t(idx_ign);

fprintf('\n  Burn time:      %.3f s  (threshold: %.1f N = 5%% peak)\n', burn_time, thresh_burn);
fprintf('  Operating time: %.3f s  (threshold: %.1f N)\n', operating_time, thresh_op);

%% ========== 8. Performance Parameters ==========
g0   = 9.80665;
Dt   = 17e-3;                          % 목 직경 [m]
At   = pi/4 * Dt^2;                    % 목 면적 [m²]

fprintf('\n========== Hot-Fire Test Performance Summary ==========\n');
fprintf('  Test: %s  (%s)\n', TEST_NAME, TEST_DATE);

% --- Burn Time 성능 ---
I_burn = trapz(t(idx_ign:idx_burn_end), F_N(idx_ign:idx_burn_end));
F_avg_burn = I_burn / burn_time;

dm_ox_burn = mass_fill(idx_ign) - mass_fill(idx_burn_end);
mdot_ox_burn = dm_ox_burn / burn_time;
Pc_post_avg_burn = mean(Pc_post_f(idx_ign:idx_burn_end));
Cf_burn = F_avg_burn / (Pc_post_avg_burn * 1e5 * At);

% --- Operating Time 성능 ---
I_op = trapz(t(idx_ign:idx_op_end), F_N(idx_ign:idx_op_end));
F_avg_op = I_op / operating_time;

dm_ox_op = mass_fill(idx_ign) - mass_fill(idx_op_end);
mdot_ox_op = dm_ox_op / operating_time;
Pc_post_avg_op = mean(Pc_post_f(idx_ign:idx_op_end));
Cf_op = F_avg_op / (Pc_post_avg_op * 1e5 * At);

% --- 공통 ---
dm_fuel = MOTOR.m_fuel_initial;   % ★ 실측값 입력 필요
dm_prop_burn = dm_ox_burn + dm_fuel;
dm_prop_op   = dm_ox_op   + dm_fuel;

OF_burn = dm_ox_burn / max(dm_fuel, 1e-6);
OF_op   = dm_ox_op   / max(dm_fuel, 1e-6);

Isp_burn = I_burn / (dm_prop_burn * g0);
Isp_op   = I_op   / (dm_prop_op   * g0);

c_star_burn = (Pc_post_avg_burn*1e5) * At / (dm_prop_burn / burn_time);
c_star_op   = (Pc_post_avg_op*1e5)   * At / (dm_prop_op / operating_time);

Pc_pre_avg_burn  = mean(Pc_pre_f(idx_ign:idx_burn_end));
Pc_pre_avg_op    = mean(Pc_pre_f(idx_ign:idx_op_end));
Pc_pre_max  = max(Pc_pre_f(idx_ign:idx_op_end));
Pc_post_max = max(Pc_post_f(idx_ign:idx_op_end));

motor_class_burn = get_motor_class(I_burn);
motor_class_op   = get_motor_class(I_op);

fprintf('\n  %-30s  %10s  %10s\n', '', 'Burn', 'Operating');
fprintf('  %s\n', repmat('-', 1, 54));
fprintf('  %-30s  %10.3f  %10.3f\n', 'Duration [s]',       burn_time, operating_time);
fprintf('  %-30s  %10.1f  %10.1f\n', 'Peak Thrust [N]',    F_max, F_max);
fprintf('  %-30s  %10.1f  %10.1f\n', 'Average Thrust [N]', F_avg_burn, F_avg_op);
fprintf('  %-30s  %10.1f  %10.1f\n', 'Total Impulse [N*s]',I_burn, I_op);
fprintf('  %-30s  %10s  %10s\n',     'Motor Class',        motor_class_burn, motor_class_op);
fprintf('  %-30s  %10.1f  %10.1f\n', 'Isp [s]',           Isp_burn, Isp_op);
fprintf('  %-30s  %10.3f  %10.3f\n', 'Cf',                Cf_burn, Cf_op);
fprintf('  %-30s  %10.1f  %10.1f\n', 'c* [m/s]',          c_star_burn, c_star_op);
fprintf('  %-30s  %10.2f  %10.2f\n', 'O/F ratio',         OF_burn, OF_op);
fprintf('  %-30s  %10.3f  %10.3f\n', 'Ox consumed [kg]',  dm_ox_burn, dm_ox_op);
fprintf('  %-30s  %10.3f  %10.3f\n', 'mdot_ox avg [kg/s]',mdot_ox_burn, mdot_ox_op);
fprintf('  %-30s  %10.1f  %10.1f\n', 'Pc_post avg [bar]', Pc_post_avg_burn, Pc_post_avg_op);
fprintf('  %s\n', repmat('-', 1, 54));
fprintf('  Pc_pre  max: %.1f bar  |  Pc_post max: %.1f bar\n', Pc_pre_max, Pc_post_max);
fprintf('  P_tank init: %.1f bar\n', P_tank_f(idx_ign));
fprintf('  Fill mass (peak/ign): %.3f / %.3f kg\n', max(mass_fill(1:idx_ign)), mass_fill(idx_ign));

%% ========== 9. Report Figures (English, Publication Quality) ==========
FONT_SIZE    = 12;
TITLE_SIZE   = 13;
SGTITLE_SIZE = 14;
LINE_WIDTH   = 1.4;
FIG_W = 800;  FIG_H = 500;

COLOR_F     = [0.85, 0.33, 0.10];   % red-orange (thrust)
COLOR_Pt    = [0.00, 0.45, 0.74];   % blue (tank pressure)
COLOR_Pcpre = [0.47, 0.67, 0.19];   % green (Pc pre)
COLOR_Pcpost= [0.64, 0.08, 0.18];   % dark red (Pc post)
COLOR_mass  = [0.49, 0.18, 0.56];   % purple (mass)
COLOR_mdot  = [0.30, 0.75, 0.93];   % light blue (mdot)

format_ax = @(ax) set(ax, 'FontSize', FONT_SIZE, 'LineWidth', 0.8, ...
    'TickDir', 'out', 'Box', 'on', 'TickLength', [0.012 0.012]);

% ─────────────────────────────────────────────────────────────────────────
% Figure 1: Thrust
% ─────────────────────────────────────────────────────────────────────────
fig1 = figure('Position', [50, 80, FIG_W, FIG_H], 'Color', 'w');
ax = gca;
plot(t, F_N, '-', 'Color', COLOR_F, 'LineWidth', LINE_WIDTH);
hold on;
xline(0, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 0.8);
yline(thresh_burn, ':', 'Color', 'r', 'LineWidth', 0.8, 'Alpha', 0.6);
xline(t(idx_burn_end), '--', 'Color', 'r', 'LineWidth', 0.9, 'Alpha', 0.7);
xline(t(idx_op_end),   '--', 'Color', [1 0.6 0], 'LineWidth', 0.9, 'Alpha', 0.7);
hold off;
xlim(T_WIN);
ylim([min(0, min(F_N)*1.05), max(F_N)*1.15]);
xlabel('Time [s]', 'FontSize', FONT_SIZE);
ylabel('Thrust [N]', 'FontSize', FONT_SIZE);
title(sprintf('%s  -  Thrust vs Time  (%s)', TEST_NAME, TEST_DATE), ...
    'FontSize', TITLE_SIZE);
grid on;  set(ax, 'GridAlpha', 0.15);
format_ax(ax);

% ─────────────────────────────────────────────────────────────────────────
% Figure 2: Chamber Pressure (Pc_pre + Pc_post)
% ─────────────────────────────────────────────────────────────────────────
fig2 = figure('Position', [100, 80, FIG_W, FIG_H], 'Color', 'w');
ax = gca;
plot(t, Pc_pre_f,  '-', 'Color', COLOR_Pcpre, 'LineWidth', LINE_WIDTH); hold on;
plot(t, Pc_post_f, '-', 'Color', COLOR_Pcpost, 'LineWidth', LINE_WIDTH);
xline(0, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 0.8);
hold off;
xlim(T_WIN);
xlabel('Time [s]', 'FontSize', FONT_SIZE);
ylabel('Chamber Pressure [bar]', 'FontSize', FONT_SIZE);
title(sprintf('%s  -  Chamber Pressure  (%s)', TEST_NAME, TEST_DATE), ...
    'FontSize', TITLE_SIZE);
legend('Pre-chamber (P_{c,pre})', 'Post-chamber (P_{c,post})', ...
    'Location', 'northeast', 'FontSize', FONT_SIZE-1);
grid on;  set(ax, 'GridAlpha', 0.15);
format_ax(ax);

% ─────────────────────────────────────────────────────────────────────────
% Figure 3: Tank Pressure
% ─────────────────────────────────────────────────────────────────────────
fig3 = figure('Position', [150, 80, FIG_W, FIG_H], 'Color', 'w');
ax = gca;
plot(t, P_tank_f, '-', 'Color', COLOR_Pt, 'LineWidth', LINE_WIDTH);
hold on;
xline(0, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 0.8);
hold off;
xlim(T_WIN);
xlabel('Time [s]', 'FontSize', FONT_SIZE);
ylabel('Tank Pressure [bar]', 'FontSize', FONT_SIZE);
title(sprintf('%s  -  Oxidizer Tank Pressure  (%s)', TEST_NAME, TEST_DATE), ...
    'FontSize', TITLE_SIZE);
grid on;  set(ax, 'GridAlpha', 0.15);
format_ax(ax);

% ─────────────────────────────────────────────────────────────────────────
% Figure 4: Oxidizer Fill Mass (Remaining)
% ─────────────────────────────────────────────────────────────────────────
fig4 = figure('Position', [200, 80, FIG_W, FIG_H], 'Color', 'w');
ax = gca;
plot(t, mass_fill, '-', 'Color', COLOR_mass, 'LineWidth', LINE_WIDTH);
hold on;
xline(0, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 0.8);
hold off;
xlim(T_WIN);
ylim([0, max(mass_fill)*1.1]);
xlabel('Time [s]', 'FontSize', FONT_SIZE);
ylabel('Oxidizer Fill Mass [kg]', 'FontSize', FONT_SIZE);
title(sprintf('%s  -  Oxidizer Fill Mass  (%s)', TEST_NAME, TEST_DATE), ...
    'FontSize', TITLE_SIZE);
grid on;  set(ax, 'GridAlpha', 0.15);
format_ax(ax);

% ─────────────────────────────────────────────────────────────────────────
% Figure 5: Summary (4-panel)
% ─────────────────────────────────────────────────────────────────────────
fig5 = figure('Position', [250, 80, FIG_W+100, 850], 'Color', 'w');

% Panel 1: Thrust
ax1 = subplot(4,1,1);
plot(t, F_N, '-', 'Color', COLOR_F, 'LineWidth', LINE_WIDTH);
hold on; xline(0, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 0.8); hold off;
xlim(T_WIN); ylabel('Thrust [N]', 'FontSize', FONT_SIZE);
title(sprintf('%s  -  Summary  (%s)', TEST_NAME, TEST_DATE), 'FontSize', TITLE_SIZE);
grid on; set(ax1, 'GridAlpha', 0.15); format_ax(ax1);

% Panel 2: Chamber Pressure
ax2 = subplot(4,1,2);
plot(t, Pc_pre_f, '-', 'Color', COLOR_Pcpre, 'LineWidth', 1.2); hold on;
plot(t, Pc_post_f, '-', 'Color', COLOR_Pcpost, 'LineWidth', 1.2);
xline(0, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 0.8); hold off;
xlim(T_WIN); ylabel('P_c [bar]', 'FontSize', FONT_SIZE);
legend('Pre', 'Post', 'Location', 'northeast', 'FontSize', FONT_SIZE-2);
grid on; set(ax2, 'GridAlpha', 0.15); format_ax(ax2);

% Panel 3: Tank Pressure
ax3 = subplot(4,1,3);
plot(t, P_tank_f, '-', 'Color', COLOR_Pt, 'LineWidth', LINE_WIDTH);
hold on; xline(0, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 0.8); hold off;
xlim(T_WIN); ylabel('P_{tank} [bar]', 'FontSize', FONT_SIZE);
grid on; set(ax3, 'GridAlpha', 0.15); format_ax(ax3);

% Panel 4: Oxidizer mass flow rate
ax4 = subplot(4,1,4);
plot(t, mdot, '-', 'Color', COLOR_mdot, 'LineWidth', LINE_WIDTH);
hold on; xline(0, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 0.8); hold off;
xlim(T_WIN); ylim([-0.02, max(mdot)*1.2]);
ylabel('mdot_{ox} [kg/s]', 'FontSize', FONT_SIZE);
xlabel('Time [s]', 'FontSize', FONT_SIZE);
grid on; set(ax4, 'GridAlpha', 0.15); format_ax(ax4);

linkaxes([ax1 ax2 ax3 ax4], 'x');

%% ========== 10. Save Report Figures ==========
fprintf('\nSaving report figures...\n');
save_dir = fileparts(mfilename('fullpath'));
if isempty(save_dir), save_dir = pwd; end

report_figs  = {fig1, fig2, fig3, fig4, fig5};
report_names = { ...
    'Fig_Thrust', ...
    'Fig_ChamberPressure', ...
    'Fig_TankPressure', ...
    'Fig_OxidizerFillMass', ...
    'Fig_Summary' ...
};
for i = 1:length(report_figs)
    save_path = fullfile(save_dir, report_names{i});
    print(report_figs{i}, save_path, '-dpng', '-r300');
    fprintf('  %s.png  (300 dpi)\n', report_names{i});
end
fprintf('\nDone - %d figures saved to:\n  %s\n', length(report_figs), save_dir);

%% ========== 11. Performance Summary Table (for report) ==========
fprintf('\n========== Performance Table (Copy to Report) ==========\n');
fprintf('%-28s  %12s  %12s\n', 'Parameter', 'Burn', 'Operating');
fprintf('%s\n', repmat('-', 1, 55));
fprintf('%-28s  %12.3f  %12.3f\n', 'Duration [s]',       burn_time, operating_time);
fprintf('%-28s  %12.1f  %12.1f\n', 'Peak thrust [N]',    F_max, F_max);
fprintf('%-28s  %12.1f  %12.1f\n', 'Average thrust [N]', F_avg_burn, F_avg_op);
fprintf('%-28s  %12.1f  %12.1f\n', 'Total impulse [N*s]',I_burn, I_op);
fprintf('%-28s  %12s  %12s\n',     'Motor class',        motor_class_burn, motor_class_op);
fprintf('%-28s  %12.1f  %12.1f\n', 'Isp [s]',           Isp_burn, Isp_op);
fprintf('%-28s  %12.3f  %12.3f\n', 'Cf',                Cf_burn, Cf_op);
fprintf('%-28s  %12.1f  %12.1f\n', 'c* [m/s]',          c_star_burn, c_star_op);
fprintf('%-28s  %12.2f  %12.2f\n', 'O/F ratio',         OF_burn, OF_op);
fprintf('%-28s  %12.3f  %12.3f\n', 'Ox consumed [kg]',  dm_ox_burn, dm_ox_op);
fprintf('%-28s  %12.3f  %12.3f\n', 'mdot_ox [kg/s]',    mdot_ox_burn, mdot_ox_op);
fprintf('%-28s  %12.1f  %12.1f\n', 'Pc_post avg [bar]', Pc_post_avg_burn, Pc_post_avg_op);
fprintf('%s\n', repmat('-', 1, 55));
fprintf('%-28s  %.1f bar\n', 'P_tank (initial)',  P_tank_f(idx_ign));
fprintf('%-28s  %.1f bar\n', 'Pc_pre (max)',      Pc_pre_max);
fprintf('%-28s  %.1f bar\n', 'Pc_post (max)',     Pc_post_max);
fprintf('%s\n', repmat('=', 1, 55));


%% ========== 12. Excel Export ==========
fprintf('\nExporting to Excel...\n');

% Export window: t = [-5, 15] s, downsample to 200 Hz
export_mask = (t >= -5) & (t <= 15);
export_idx  = find(export_mask);
ds_step     = round(fs / 200);  % downsample factor (2000/200 = 10)
export_idx  = export_idx(1:ds_step:end);

% Build table
T_export = table( ...
    t(export_idx), ...
    F_N(export_idx), ...
    mass_f(export_idx), ...
    mass_fill(export_idx), ...
    P_tank_f(export_idx), ...
    Pc_pre_f(export_idx), ...
    Pc_post_f(export_idx), ...
    'VariableNames', {'Time_s', 'Thrust_N', 'TankMass_kg', ...
                      'FillMass_kg', 'P_tank_bar', 'Pc_pre_bar', 'Pc_post_bar'});

xlsx_path = fullfile(save_dir, 'HotFire_2026_ProcessedData.xlsx');
writetable(T_export, xlsx_path, 'Sheet', 'Filtered Data');
fprintf('  Saved: %s (%d rows at 200 Hz)\n', xlsx_path, height(T_export));

% Performance summary sheet (Burn / Operating 비교)
perf_params = {'Duration [s]'; 'Peak Thrust [N]'; 'Average Thrust [N]'; ...
               'Total Impulse [N*s]'; 'Motor Class'; ...
               'Isp [s]'; 'Cf'; 'c* [m/s]'; 'O/F ratio'; ...
               'Ox consumed [kg]'; 'mdot_ox avg [kg/s]'; 'Pc_post avg [bar]'};
perf_burn   = {burn_time; F_max; F_avg_burn; I_burn; motor_class_burn; ...
               Isp_burn; Cf_burn; c_star_burn; OF_burn; ...
               dm_ox_burn; mdot_ox_burn; Pc_post_avg_burn};
perf_op     = {operating_time; F_max; F_avg_op; I_op; motor_class_op; ...
               Isp_op; Cf_op; c_star_op; OF_op; ...
               dm_ox_op; mdot_ox_op; Pc_post_avg_op};
T_perf = table(perf_params, perf_burn, perf_op, ...
    'VariableNames', {'Parameter', 'Burn_Time', 'Operating_Time'});
writetable(T_perf, xlsx_path, 'Sheet', 'Performance');
fprintf('  Performance sheet added (Burn / Operating).\n');

fprintf('\n========== ALL DONE ==========\n');

%% ═══════════════════════════════════════════════════════════════════════
%  Local function: NAR/TRA motor class
%% ═══════════════════════════════════════════════════════════════════════
function cls = get_motor_class(I_total_Ns)
if I_total_Ns <= 0
    cls = 'N/A'; return;
end
letters = 'ABCDEFGHIJKLMNO';
limits  = 2.5 * (2 .^ (0:14));
idx = find(I_total_Ns <= limits, 1, 'first');
if isempty(idx)
    cls = 'O+';
else
    cls = letters(idx);
end
end