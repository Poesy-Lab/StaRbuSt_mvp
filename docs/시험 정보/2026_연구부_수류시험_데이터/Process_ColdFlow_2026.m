%% Process_ColdFlow_2026.m
%  2026 수류시험 LVM 데이터 가공 및 분석
%  - 캘리브레이션 적용 (2025년 센서 교정값)
%  - 로드셀 필터링 + 질량유량 계산
%  - 두 테스트 비교
%
%  입력: 2026_test.lvm, 2026_test_2.lvm
%  출력: 그래프 4장 (압력, dP, 질량, 유량)

clear; clc; close all;

%% ========== 1. 캘리브레이션 계수 (2025년 교정값) ==========
% P [bar] = a * V [V] + b

% 100 bar 센서 — 산화제 탱크 압력 (2026 캘리)
cal_tank.a = 6174.602420;
cal_tank.b = -24.591340;

% 50 bar 센서 — 인젝터 전방 압력 (2026 캘리)
cal_inj.a = 3118.719080;
cal_inj.b = -12.407200;

% 로드셀 — 산화제 탱크 중량 [kg] (2026 캘리)
cal_load.a = 3108.705160;
cal_load.b = -12.343940;

%% ========== 2. 데이터 읽기 ==========
fprintf('데이터 읽는 중...\n');

raw1 = readmatrix('2026_test.lvm', 'FileType', 'text');
raw2 = readmatrix('2026_test_2.lvm', 'FileType', 'text');

data = struct();

% Test 1
data(1).name   = 'Test 1';
data(1).t      = raw1(:, 1);
data(1).P_tank = cal_tank.a * raw1(:, 2) + cal_tank.b;   % [bar]
data(1).P_inj  = cal_inj.a  * raw1(:, 3) + cal_inj.b;    % [bar]
data(1).mass   = cal_load.a * raw1(:, 4) + cal_load.b;    % [kg]

% Test 2
data(2).name   = 'Test 2';
data(2).t      = raw2(:, 1);
data(2).P_tank = cal_tank.a * raw2(:, 2) + cal_tank.b;
data(2).P_inj  = cal_inj.a  * raw2(:, 3) + cal_inj.b;
data(2).mass   = cal_load.a * raw2(:, 4) + cal_load.b;

%% ========== 3. 로드셀 필터링 + 유량 계산 ==========
% 5 kHz 샘플링 → 노이즈 심함 → 이동평균 필터 적용 후 미분

dt = 0.0002;                    % 샘플링 간격 [s] (5 kHz)
N_smooth_mass = 2500;           % 질량 이동평균 윈도우 (0.5s)
N_smooth_mdot = 5000;           % 유량 추가 스무딩 윈도우 (1.0s)

for k = 1:2
    % 질량 스무딩
    data(k).mass_filt = movmean(data(k).mass, N_smooth_mass);

    % 질량유량 = -d(mass)/dt  [kg/s]  (질량 감소 → 유량 양수)
    dmdt = gradient(data(k).mass_filt, dt);
    data(k).mdot = movmean(-dmdt, N_smooth_mdot);

    % 압력 차이
    data(k).dP = data(k).P_tank - data(k).P_inj;

    % 압력도 가볍게 스무딩 (시각화용, 100-pt = 0.02s)
    data(k).P_tank_filt = movmean(data(k).P_tank, 100);
    data(k).P_inj_filt  = movmean(data(k).P_inj, 100);
    data(k).dP_filt     = data(k).P_tank_filt - data(k).P_inj_filt;
end

%% ========== 4. 기본 통계 + 적분 교차검증 ==========
fprintf('\n========== 수류시험 데이터 요약 ==========\n');
for k = 1:2
    % 로드셀 직접 측정: 전후 질량 차
    dm_loadcell = data(k).mass_filt(1) - min(data(k).mass_filt);

    % mdot 적분: ∫mdot·dt (trapz)
    dm_integral = trapz(data(k).t, data(k).mdot);

    % 오차율
    err_pct = (dm_integral - dm_loadcell) / dm_loadcell * 100;

    fprintf('\n--- %s ---\n', data(k).name);
    fprintf('  측정 시간  : %.2f s  (샘플 %d개, %.0f Hz)\n', ...
        data(k).t(end), length(data(k).t), 1/dt);
    fprintf('  P_tank     : 초기 %.1f → 최종 %.1f bar\n', ...
        data(k).P_tank_filt(1), data(k).P_tank_filt(end));
    fprintf('  P_inj(max) : %.1f bar\n', max(data(k).P_inj_filt));
    fprintf('  질량       : 초기 %.3f → 최종 %.3f kg\n', ...
        data(k).mass_filt(1), data(k).mass_filt(end));
    fprintf('  토출 질량 (로드셀)  : %.3f kg\n', dm_loadcell);
    fprintf('  토출 질량 (mdot적분): %.3f kg\n', dm_integral);
    fprintf('  적분 교차검증 오차  : %+.1f%%\n', err_pct);
    fprintf('  최대 유량  : %.3f kg/s\n', max(data(k).mdot));

    % 유동 구간 판별: 최대 유량의 5% 이상인 구간을 활성 유동으로 정의
    mdot_threshold = max(data(k).mdot) * 0.05;
    flow_idx = find(data(k).mdot > mdot_threshold);
    t_flow_start = data(k).t(flow_idx(1));
    t_flow_end   = data(k).t(flow_idx(end));
    t_flow_dur   = t_flow_end - t_flow_start;

    % 활성 구간 평균 유량
    mdot_avg_active = trapz(data(k).t(flow_idx(1):flow_idx(end)), ...
                            data(k).mdot(flow_idx(1):flow_idx(end))) / t_flow_dur;

    fprintf('  유동 구간  : %.2f ~ %.2f s  (%.2f s)\n', t_flow_start, t_flow_end, t_flow_dur);
    fprintf('  평균 유량 (유동구간): %.3f kg/s\n', mdot_avg_active);

    data(k).dm_loadcell = dm_loadcell;
    data(k).dm_integral = dm_integral;
    data(k).t_flow_start = t_flow_start;
    data(k).t_flow_end   = t_flow_end;
    data(k).mdot_avg     = mdot_avg_active;
end

%% ========== 5. 플롯 ==========
colors = {'b', 'r'};
fig_w = 900; fig_h = 800;

% --- Figure 1: 압력 시계열 ---
figure('Position', [50, 50, fig_w, fig_h]);
for k = 1:2
    subplot(2,1,k)
    plot(data(k).t, data(k).P_tank_filt, 'b-', 'LineWidth', 1.2); hold on;
    plot(data(k).t, data(k).P_inj_filt,  'r-', 'LineWidth', 1.2);
    xlabel('Time [s]'); ylabel('Pressure [bar]');
    title(sprintf('%s — 탱크 / 인젝터 전방 압력', data(k).name));
    legend('P_{tank} (100bar)', 'P_{inj} (50bar avg)', 'Location', 'northeast');
    grid on; xlim([0, data(k).t(end)]);
end
sgtitle('2026 수류시험 — 압력 시계열 (2026 캘리)', 'FontWeight', 'bold');

% --- Figure 2: dP ---
figure('Position', [100, 50, fig_w, 500]);
for k = 1:2
    plot(data(k).t, data(k).dP_filt, colors{k}, 'LineWidth', 1.2); hold on;
end
xlabel('Time [s]'); ylabel('\DeltaP (tank - inj) [bar]');
title('인젝터 전후 압력 차이');
legend('Test 1', 'Test 2', 'Location', 'northeast');
grid on;

% --- Figure 3: 질량 ---
figure('Position', [150, 50, fig_w, 500]);
for k = 1:2
    plot(data(k).t, data(k).mass_filt, colors{k}, 'LineWidth', 1.2); hold on;
end
xlabel('Time [s]'); ylabel('Mass [kg]');
title('산화제 탱크 질량 (로드셀, 필터링)');
legend('Test 1', 'Test 2', 'Location', 'northeast');
grid on;

% --- Figure 4: 질량유량 ---
figure('Position', [200, 50, fig_w, 500]);
for k = 1:2
    plot(data(k).t, data(k).mdot, colors{k}, 'LineWidth', 1.2); hold on;
end
xlabel('Time [s]'); ylabel('Mass flow rate [kg/s]');
title('인젝터 토출 산화제 유량 (= -d(mass)/dt)');
legend('Test 1', 'Test 2', 'Location', 'northeast');
grid on; ylim([-0.1, max(max(data(1).mdot), max(data(2).mdot)) * 1.2]);

% --- Figure 5: 종합 비교 (Test 1 기준) ---
figure('Position', [250, 50, fig_w, fig_h]);
k = 1;  % Test 1 상세
subplot(4,1,1)
plot(data(k).t, data(k).P_tank_filt, 'b-', 'LineWidth', 1.2); hold on;
plot(data(k).t, data(k).P_inj_filt, 'r-', 'LineWidth', 1.2);
ylabel('P [bar]'); legend('P_{tank}', 'P_{inj}'); grid on;
title('Test 1 — 종합 시계열');

subplot(4,1,2)
plot(data(k).t, data(k).dP_filt, 'g-', 'LineWidth', 1.2);
ylabel('\DeltaP [bar]'); grid on;

subplot(4,1,3)
plot(data(k).t, data(k).mass_filt, 'k-', 'LineWidth', 1.2);
ylabel('Mass [kg]'); grid on;

subplot(4,1,4)
plot(data(k).t, data(k).mdot, 'm-', 'LineWidth', 1.2);
ylabel('mdot [kg/s]'); xlabel('Time [s]'); grid on;
ylim([-0.1, max(data(k).mdot) * 1.2]);

% --- Figure 6: 종합 비교 (Test 2 기준) ---
figure('Position', [300, 50, fig_w, fig_h]);
k = 2;
subplot(4,1,1)
plot(data(k).t, data(k).P_tank_filt, 'b-', 'LineWidth', 1.2); hold on;
plot(data(k).t, data(k).P_inj_filt, 'r-', 'LineWidth', 1.2);
ylabel('P [bar]'); legend('P_{tank}', 'P_{inj}'); grid on;
title('Test 2 — 종합 시계열');

subplot(4,1,2)
plot(data(k).t, data(k).dP_filt, 'g-', 'LineWidth', 1.2);
ylabel('\DeltaP [bar]'); grid on;

subplot(4,1,3)
plot(data(k).t, data(k).mass_filt, 'k-', 'LineWidth', 1.2);
ylabel('Mass [kg]'); grid on;

subplot(4,1,4)
plot(data(k).t, data(k).mdot, 'm-', 'LineWidth', 1.2);
ylabel('mdot [kg/s]'); xlabel('Time [s]'); grid on;
ylim([-0.1, max(data(k).mdot) * 1.2]);

% --- Figure 7: 스무딩 효과 검증 (Test 1) ---
%   다양한 윈도우 크기로 mdot 비교 → bell shape가 실제인지 아티팩트인지 확인
figure('Position', [350, 50, fig_w, fig_h]);
k = 1;
windows = [1000, 2500, 5000, 10000];  % 질량 스무딩: 0.2s, 0.5s, 1.0s, 2.0s
mdot_window = 5000;  % mdot 스무딩 고정 (1.0s)
sc = {'c', 'b', 'r', 'm'};

subplot(2,1,1)
for w = 1:length(windows)
    m_smooth = movmean(data(k).mass, windows(w));
    dm = gradient(m_smooth, dt);
    md = movmean(-dm, mdot_window);
    plot(data(k).t, md, sc{w}, 'LineWidth', 1.2); hold on;
end
xlabel('Time [s]'); ylabel('mdot [kg/s]');
title('Test 1 - mass smoothing window size vs mdot shape');
legend(arrayfun(@(w) sprintf('mass win = %.1fs', w/5000), windows, 'UniformOutput', false), ...
    'Location', 'northeast');
grid on; ylim([-0.1, 0.8]);

subplot(2,1,2)
for w = 1:length(windows)
    m_smooth = movmean(data(k).mass, windows(w));
    plot(data(k).t, m_smooth, sc{w}, 'LineWidth', 1.2); hold on;
end
xlabel('Time [s]'); ylabel('Mass [kg]');
title('Test 1 - smoothed mass curves');
legend(arrayfun(@(w) sprintf('win = %.1fs', w/5000), windows, 'UniformOutput', false), ...
    'Location', 'northeast');
grid on;

%% ========== 6. Cd 토출계수 계산 (SPI / HEM / NHNE) ==========
fprintf('\nCd 계산 중...\n');

% 시뮬레이션 물성 함수 경로 추가
sim_root = fileparts(pwd);  % 상위 폴더 = StaRbuSt-Simulatrion(MATLAB)
addpath(fullfile(sim_root, 'System'));
addpath(fullfile(sim_root, 'Props'));

% 인젝터 사양
d_orifice = 1.4e-3;        % 오리피스 직경 [m]
n_orifice = 28;             % 오리피스 개수
A_inj = n_orifice * pi/4 * d_orifice^2;   % 총 인젝터 면적 [m²]
P_atm = 1.01325e5;         % 대기압 [Pa]

fprintf('  A_inj = %.4e m² (d=%.1fmm x %d holes)\n', A_inj, d_orifice*1e3, n_orifice);

for k = 1:2
    N = length(data(k).t);
    Cd_SPI  = NaN(N, 1);
    Cd_HEM  = NaN(N, 1);
    Cd_NHNE = NaN(N, 1);
    G_SPI_arr  = NaN(N, 1);
    G_HEM_arr  = NaN(N, 1);
    G_NHNE_arr = NaN(N, 1);

    % 유동 활성 구간에서만 계산 (mdot > 5% peak)
    mdot_th = max(data(k).mdot) * 0.05;
    active  = find(data(k).mdot > mdot_th);

    % 다운샘플: 5kHz 전부 돌리면 느리므로 50-pt 간격 (100Hz)
    step = 50;
    calc_idx = active(1):step:active(end);

    for ii = 1:length(calc_idx)
        idx = calc_idx(ii);
        P1_bar = data(k).P_inj_filt(idx);   % 인젝터 전방 압력 [bar]
        P1_Pa  = P1_bar * 1e5;               % [Pa]
        P2_Pa  = P_atm;                      % 대기 방출

        if P1_Pa <= P2_Pa || data(k).mdot(idx) <= 0
            continue;
        end

        % T_sat(P_inj) → N2O 포화 온도 역산 (Wagner 반복)
        T_sat = Tsat_from_P(P1_Pa);
        if isnan(T_sat), continue; end

        % 포화 물성
        [Psat, rhoL, rhoV, hL, hV] = Get_N2O_Sat(T_sat);
        hfg  = max(hV - hL, 1e3);
        v0   = 1 / max(rhoL, 1);
        vfg  = max(1/max(rhoV,0.1) - v0, 0);

        % c_pL (유한차분)
        dT = 2.0;
        [~,~,~,hL_m,~] = Get_N2O_Sat(max(T_sat - dT, 184));
        cpL = max((hL - hL_m) / dT, 500);

        % omega (Nino Eq.8, chi_i = 0)
        omega = (cpL * T_sat * P1_Pa / max(v0,1e-6)) * (vfg / max(hfg,1))^2;
        omega = max(omega, 0.1);

        % --- G_SPI ---
        G_spi = sqrt(2 * rhoL * max(P1_Pa - P2_Pa, 0));

        % --- G_HEM (Omega 해석적 적분) ---
        eta_b = max(P2_Pa / Psat, 1e-4);
        if P1_Pa >= Psat
            % 과냉/포화 입구
            G_sq_1ph = 2 * rhoL * max(P1_Pa - Psat, 0);
            if abs(omega - 1) < 1e-6
                I_val = -log(eta_b);
            else
                I_val = (1/(1-omega)) * log(1 / max(omega + (1-omega)*eta_b, 1e-12));
            end
            G_hem = sqrt(max(G_sq_1ph + 2*rhoL*Psat*max(I_val,0), 0));
        else
            % 자발가압 (P1 < Psat)
            eta_t = P1_Pa / Psat;
            if eta_t <= eta_b
                G_hem = 0;
            else
                if abs(omega - 1) < 1e-6
                    I_val = log(eta_t / eta_b);
                else
                    d_b = max(omega + (1-omega)*eta_b, 1e-12);
                    d_t = max(omega + (1-omega)*eta_t, 1e-12);
                    I_val = (1/(1-omega)) * log(d_t / d_b);
                end
                G_hem = sqrt(max(2*rhoL*Psat*max(I_val,0), 0));
            end
        end

        % --- G_NHNE (Dyer, kappa=1 for self-pressurized) ---
        if P2_Pa >= Psat
            kappa = inf;
        else
            kappa = sqrt(max((P1_Pa - P2_Pa) / max(Psat - P2_Pa, 1), 0));
        end
        w_hem  = 1 / (1 + kappa);
        G_nhne = (1 - w_hem) * G_spi + w_hem * G_hem;

        % 실측 질량플럭스
        G_exp = data(k).mdot(idx) / A_inj;

        % Cd = G_exp / G_theoretical
        G_SPI_arr(idx)  = G_spi;
        G_HEM_arr(idx)  = G_hem;
        G_NHNE_arr(idx) = G_nhne;

        if G_spi  > 0, Cd_SPI(idx)  = G_exp / G_spi;  end
        if G_hem  > 0, Cd_HEM(idx)  = G_exp / G_hem;  end
        if G_nhne > 0, Cd_NHNE(idx) = G_exp / G_nhne; end
    end

    data(k).Cd_SPI  = Cd_SPI;
    data(k).Cd_HEM  = Cd_HEM;
    data(k).Cd_NHNE = Cd_NHNE;
    data(k).G_SPI   = G_SPI_arr;
    data(k).G_HEM   = G_HEM_arr;
    data(k).G_NHNE  = G_NHNE_arr;

    % 유동 구간 Cd 통계
    valid = isfinite(Cd_SPI);
    fprintf('\n--- %s Cd 통계 (유동 구간) ---\n', data(k).name);
    fprintf('  Cd_SPI  : 평균 %.4f, std %.4f (범위 %.3f ~ %.3f)\n', ...
        mean(Cd_SPI(valid)), std(Cd_SPI(valid)), min(Cd_SPI(valid)), max(Cd_SPI(valid)));
    valid = isfinite(Cd_HEM);
    fprintf('  Cd_HEM  : 평균 %.4f, std %.4f (범위 %.3f ~ %.3f)\n', ...
        mean(Cd_HEM(valid)), std(Cd_HEM(valid)), min(Cd_HEM(valid)), max(Cd_HEM(valid)));
    valid = isfinite(Cd_NHNE);
    fprintf('  Cd_NHNE : 평균 %.4f, std %.4f (범위 %.3f ~ %.3f)\n', ...
        mean(Cd_NHNE(valid)), std(Cd_NHNE(valid)), min(Cd_NHNE(valid)), max(Cd_NHNE(valid)));
end

%% ========== 6b. 시스템 Cd 계산 (P1=P_tank, P2=P_atm) ==========
% 전체 피드 시스템(파이프+확장부+인젝터)의 유효 토출계수
% 연소시험에서는 P2=P_chamber로 대체하여 직접 비교 가능
fprintf('\n시스템 Cd 계산 중 (P1=P_tank, P2=P_atm)...\n');

for k = 1:2
    N = length(data(k).t);
    Cd_sys_SPI  = NaN(N, 1);
    Cd_sys_HEM  = NaN(N, 1);
    Cd_sys_NHNE = NaN(N, 1);

    % 유동 활성 구간
    mdot_th = max(data(k).mdot) * 0.05;
    active  = find(data(k).mdot > mdot_th);

    step = 50;
    calc_idx = active(1):step:active(end);

    for ii = 1:length(calc_idx)
        idx = calc_idx(ii);
        P1_bar = data(k).P_tank_filt(idx);  % 탱크 상부압 [bar]
        P1_Pa  = P1_bar * 1e5;
        P2_Pa  = P_atm;                     % 대기압

        if P1_Pa <= P2_Pa || data(k).mdot(idx) <= 0
            continue;
        end

        % T_sat(P_tank) — 자발가압이므로 T_tank ≈ T_sat(P_tank)
        T_sat = Tsat_from_P(P1_Pa);
        if isnan(T_sat), continue; end

        % 포화 물성
        [Psat, rhoL, rhoV, hL, hV] = Get_N2O_Sat(T_sat);
        hfg  = max(hV - hL, 1e3);
        v0   = 1 / max(rhoL, 1);
        vfg  = max(1/max(rhoV,0.1) - v0, 0);

        % c_pL
        dT = 2.0;
        [~,~,~,hL_m,~] = Get_N2O_Sat(max(T_sat - dT, 184));
        cpL = max((hL - hL_m) / dT, 500);

        % omega
        omega = (cpL * T_sat * P1_Pa / max(v0,1e-6)) * (vfg / max(hfg,1))^2;
        omega = max(omega, 0.1);

        % --- G_SPI ---
        G_spi = sqrt(2 * rhoL * max(P1_Pa - P2_Pa, 0));

        % --- G_HEM ---
        eta_b = max(P2_Pa / Psat, 1e-4);
        % 자발가압: P_tank ≈ Psat → 포화/과냉 분기
        if P1_Pa >= Psat
            G_sq_1ph = 2 * rhoL * max(P1_Pa - Psat, 0);
            if abs(omega - 1) < 1e-6
                I_val = -log(eta_b);
            else
                I_val = (1/(1-omega)) * log(1 / max(omega + (1-omega)*eta_b, 1e-12));
            end
            G_hem = sqrt(max(G_sq_1ph + 2*rhoL*Psat*max(I_val,0), 0));
        else
            eta_t = P1_Pa / Psat;
            if eta_t <= eta_b
                G_hem = 0;
            else
                if abs(omega - 1) < 1e-6
                    I_val = log(eta_t / eta_b);
                else
                    d_b = max(omega + (1-omega)*eta_b, 1e-12);
                    d_t = max(omega + (1-omega)*eta_t, 1e-12);
                    I_val = (1/(1-omega)) * log(d_t / d_b);
                end
                G_hem = sqrt(max(2*rhoL*Psat*max(I_val,0), 0));
            end
        end

        % --- G_NHNE (Dyer) ---
        if P2_Pa >= Psat
            kappa = inf;
        else
            kappa = sqrt(max((P1_Pa - P2_Pa) / max(Psat - P2_Pa, 1), 0));
        end
        w_hem  = 1 / (1 + kappa);
        G_nhne = (1 - w_hem) * G_spi + w_hem * G_hem;

        % Cd_sys = G_exp / G_theoretical
        G_exp = data(k).mdot(idx) / A_inj;

        if G_spi  > 0, Cd_sys_SPI(idx)  = G_exp / G_spi;  end
        if G_hem  > 0, Cd_sys_HEM(idx)  = G_exp / G_hem;  end
        if G_nhne > 0, Cd_sys_NHNE(idx) = G_exp / G_nhne; end
    end

    data(k).Cd_sys_SPI  = Cd_sys_SPI;
    data(k).Cd_sys_HEM  = Cd_sys_HEM;
    data(k).Cd_sys_NHNE = Cd_sys_NHNE;

    % 통계
    valid = isfinite(Cd_sys_SPI);
    fprintf('\n--- %s 시스템 Cd 통계 (P1=P_tank) ---\n', data(k).name);
    fprintf('  Cd_sys_SPI  : 평균 %.4f, std %.4f (범위 %.3f ~ %.3f)\n', ...
        mean(Cd_sys_SPI(valid)), std(Cd_sys_SPI(valid)), min(Cd_sys_SPI(valid)), max(Cd_sys_SPI(valid)));
    valid = isfinite(Cd_sys_HEM);
    fprintf('  Cd_sys_HEM  : 평균 %.4f, std %.4f (범위 %.3f ~ %.3f)\n', ...
        mean(Cd_sys_HEM(valid)), std(Cd_sys_HEM(valid)), min(Cd_sys_HEM(valid)), max(Cd_sys_HEM(valid)));
    valid = isfinite(Cd_sys_NHNE);
    fprintf('  Cd_sys_NHNE : 평균 %.4f, std %.4f (범위 %.3f ~ %.3f)\n', ...
        mean(Cd_sys_NHNE(valid)), std(Cd_sys_NHNE(valid)), min(Cd_sys_NHNE(valid)), max(Cd_sys_NHNE(valid)));
end

% --- Figure 8: Cd 시계열 비교 ---
figure('Position', [400, 50, fig_w, fig_h]);
for k = 1:2
    subplot(2,1,k)
    plot(data(k).t, data(k).Cd_SPI,  'b.', 'MarkerSize', 3); hold on;
    plot(data(k).t, data(k).Cd_HEM,  'r.', 'MarkerSize', 3);
    plot(data(k).t, data(k).Cd_NHNE, 'g.', 'MarkerSize', 3);
    yline(0.63, 'k--', 'Cd_{geo}=0.63', 'LineWidth', 1);
    xlabel('Time [s]'); ylabel('Cd [-]');
    title(sprintf('%s — Cd vs Time', data(k).name));
    legend('Cd_{SPI}', 'Cd_{HEM}', 'Cd_{NHNE}(\kappa=1)', 'Location', 'best');
    grid on; ylim([0, 1.5]);
end
sgtitle('토출계수 Cd — 모델별 비교', 'FontWeight', 'bold');

% --- Figure 9: Cd vs P_inj ---
figure('Position', [450, 50, fig_w, fig_h]);
for k = 1:2
    subplot(2,1,k)
    valid = isfinite(data(k).Cd_SPI);
    plot(data(k).P_inj_filt(valid), data(k).Cd_SPI(valid),  'b.', 'MarkerSize', 4); hold on;
    valid = isfinite(data(k).Cd_HEM);
    plot(data(k).P_inj_filt(valid), data(k).Cd_HEM(valid),  'r.', 'MarkerSize', 4);
    valid = isfinite(data(k).Cd_NHNE);
    plot(data(k).P_inj_filt(valid), data(k).Cd_NHNE(valid), 'g.', 'MarkerSize', 4);
    yline(0.63, 'k--', 'Cd_{geo}=0.63', 'LineWidth', 1);
    xlabel('P_{inj} [bar]'); ylabel('Cd [-]');
    title(sprintf('%s — Cd vs Injector Pressure', data(k).name));
    legend('Cd_{SPI}', 'Cd_{HEM}', 'Cd_{NHNE}(\kappa=1)', 'Location', 'best');
    grid on; ylim([0, 1.5]);
end
sgtitle('토출계수 Cd vs 인젝터 전방 압력', 'FontWeight', 'bold');

% --- Figure 10: 시스템 Cd 시계열 ---
figure('Position', [500, 50, fig_w, fig_h]);
for k = 1:2
    subplot(2,1,k)
    plot(data(k).t, data(k).Cd_sys_SPI,  'b.', 'MarkerSize', 3); hold on;
    plot(data(k).t, data(k).Cd_sys_HEM,  'r.', 'MarkerSize', 3);
    plot(data(k).t, data(k).Cd_sys_NHNE, 'g.', 'MarkerSize', 3);
    yline(0.63, 'k--', 'Cd_{geo}=0.63', 'LineWidth', 1);
    xlabel('Time [s]'); ylabel('Cd_{sys} [-]');
    title(sprintf('%s — System Cd vs Time (P1=P_{tank})', data(k).name));
    legend('Cd_{sys,SPI}', 'Cd_{sys,HEM}', 'Cd_{sys,NHNE}', 'Location', 'best');
    grid on; ylim([0, 1.5]);
end
sgtitle('시스템 토출계수 Cd_{sys} (P1=P_{tank}, P2=P_{atm})', 'FontWeight', 'bold');

% --- Figure 11: 시스템 Cd vs P_tank ---
figure('Position', [550, 50, fig_w, fig_h]);
for k = 1:2
    subplot(2,1,k)
    valid = isfinite(data(k).Cd_sys_SPI);
    plot(data(k).P_tank_filt(valid), data(k).Cd_sys_SPI(valid),  'b.', 'MarkerSize', 4); hold on;
    valid = isfinite(data(k).Cd_sys_HEM);
    plot(data(k).P_tank_filt(valid), data(k).Cd_sys_HEM(valid),  'r.', 'MarkerSize', 4);
    valid = isfinite(data(k).Cd_sys_NHNE);
    plot(data(k).P_tank_filt(valid), data(k).Cd_sys_NHNE(valid), 'g.', 'MarkerSize', 4);
    yline(0.63, 'k--', 'Cd_{geo}=0.63', 'LineWidth', 1);
    xlabel('P_{tank} [bar]'); ylabel('Cd_{sys} [-]');
    title(sprintf('%s — System Cd vs Tank Pressure', data(k).name));
    legend('Cd_{sys,SPI}', 'Cd_{sys,HEM}', 'Cd_{sys,NHNE}', 'Location', 'best');
    grid on; ylim([0, 1.5]);
end
sgtitle('시스템 토출계수 vs 탱크 압력', 'FontWeight', 'bold');

%% ========== 7. 그래프 저장 ==========
fprintf('\n그래프 저장 중...\n');
fig_names = { ...
    'Fig1_Pressure_TimeSeries', ...
    'Fig2_dP_Comparison', ...
    'Fig3_Mass_Comparison', ...
    'Fig4_MassFlowRate_Comparison', ...
    'Fig5_Test1_Summary', ...
    'Fig6_Test2_Summary', ...
    'Fig7_Smoothing_Sensitivity', ...
    'Fig8_Cd_vs_Time', ...
    'Fig9_Cd_vs_Pinj', ...
    'Fig10_Cd_sys_vs_Time', ...
    'Fig11_Cd_sys_vs_Ptank' ...
};
figs = findobj('Type', 'figure');
figs = sort([figs.Number]);  % 번호순 정렬
for i = 1:min(length(figs), length(fig_names))
    saveas(figure(figs(i)), [fig_names{i}, '.png']);
    fprintf('  %s.png 저장\n', fig_names{i});
end

%% ========== 7. LVM → Excel 변환 ==========
%fprintf('\n엑셀 파일 변환 중...\n');

%for k = 1:2
%    if k == 1
%        xlsx_name = '2026_test_processed.xlsx';
%    else
%        xlsx_name = '2026_test_2_processed.xlsx';
%    end

    % raw + 가공 데이터를 테이블로 구성
%    N = length(data(k).t);
%    T = table( ...
%        data(k).t, ...
%        data(k).P_tank, ...
%        data(k).P_tank_filt, ...
%        data(k).P_inj, ...
%        data(k).P_inj_filt, ...
%        data(k).dP, ...
%        data(k).dP_filt, ...
%        data(k).mass, ...
%        data(k).mass_filt, ...
%        data(k).mdot, ...
%        'VariableNames', { ...
%            'Time_s', ...
%            'P_tank_raw_bar', ...
%            'P_tank_filt_bar', ...
%            'P_inj_raw_bar', ...
%            'P_inj_filt_bar', ...
%            'dP_raw_bar', ...
%            'dP_filt_bar', ...
%            'Mass_raw_kg', ...
%            'Mass_filt_kg', ...
%            'mdot_kgs' ...
%        });

%    writetable(T, xlsx_name);
%    fprintf('  %s 저장 완료 (%d행)\n', xlsx_name, N);
%end

%fprintf('\n처리 완료. 그래프 9개 (PNG 저장) + 엑셀 2개 생성.\n');


%% ═══════════════════════════════════════════════════════════════════════════
%  로컬 함수: Tsat_from_P — Wagner 포화압력 역산 (이분법)
%% ═══════════════════════════════════════════════════════════════════════════
function T = Tsat_from_P(P_target)
% Wagner 포화압력식의 역함수: P [Pa] → T_sat [K]
% Get_N2O_Sat의 Psat(T)를 이분법으로 역산
% 범위: 182.3 K (삼중점) ~ 309.57 K (임계점)

if P_target <= 0 || ~isfinite(P_target)
    T = NaN; return;
end

T_lo = 182.3;   T_hi = 309.5;
P_lo = Get_N2O_Sat(T_lo);
P_hi = Get_N2O_Sat(T_hi);

if P_target > P_hi || P_target < P_lo
    T = NaN; return;
end

for iter = 1:50
    T_mid = (T_lo + T_hi) / 2;
    P_mid = Get_N2O_Sat(T_mid);
    if P_mid < P_target
        T_lo = T_mid;
    else
        T_hi = T_mid;
    end
    if abs(T_hi - T_lo) < 0.001  % 0.001 K 정밀도
        break;
    end
end

T = (T_lo + T_hi) / 2;
end