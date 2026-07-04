function res = Flight_From_Config(config_base, opts)
%Flight_From_Config  모터 시뮬 결과(y)로 6자유도 비행 시뮬을 헤드리스 실행
%   res = Flight_From_Config('2026_nova_line_hot')
%   res = Flight_From_Config('...', struct('total_mass',14.5,'elev_deg',80))
%
%   추력 곡선: Mat_Data/<config>/<config>_y.mat의 y.nozzle.F (점화 기준 재영점)
%   추진제 질량: 산화제 적재량(u.tank.m) + 연료 소모량(trapz y.fuel.mdot)
%   기체/발사대: opts (기본 총중량 14.5 kg, 발사각 80도, 레일 5 m — 재설계 구상.md)
%   반환: res.apogee, res.v_rail_exit, res.t_rail_exit, res.burn_alt,
%         res.v_max, res.I_total, res.F_mean, res.t_burn, res.m_prop
%   프로젝트 루트에서 실행하세요. (플롯/애니메이션 없음)

if nargin < 2, opts = struct(); end
getopt = @(f, d) get_field(opts, f, d);
total_mass = getopt('total_mass', 14.5); % 이륙 총중량 [kg]
elev_deg   = getopt('elev_deg', 80);     % 발사각 [deg]
rail_h     = getopt('rail_h', 5);        % 레일 길이 [m]

global TMS_Thrust %#ok<GVMIS>

%% 추력 곡선 로드 (점화 시점 재영점)
yfile = fullfile('Mat_Data', config_base, [config_base '_y.mat']);
if ~exist(yfile, 'file')
    error('Flight_From_Config:NoHistory', ...
        '시뮬 이력이 없습니다: %s (Run_Config(''%s'') 먼저 실행)', yfile, config_base);
end
S = load(yfile, 'y'); y = S.y;
cfg = load(fullfile('Config', [config_base '.mat']), 'u');

F = y.nozzle.F(:); t = y.time(:);
valid = isfinite(F) & F > 0;
i0 = find(valid, 1); i1 = find(valid, 1, 'last');
if isempty(i0)
    error('Flight_From_Config:NoThrust', '추력 데이터가 없습니다 (연소 모드 config인지 확인).');
end
tb = t(i0:i1) - t(i0);
Fb = F(i0:i1); Fb(~isfinite(Fb) | Fb < 0) = 0;
TMS_Thrust = [tb, Fb];

%% 추진제 질량 (산화제 적재량 + 연료 소모량)
m_ox = cfg.u.tank.m;
mf = y.fuel.mdot(:); mf(~isfinite(mf)) = 0;
m_fuel = trapz(t, mf);
m_prop = m_ox + m_fuel;

%% 기체 파라미터 주입 + 초기 상태
flight_param(struct('total_mass', total_mass, 'propulsion_mass', m_prop, ...
                    'rail_h', rail_h));
init_state = [zeros(3,1); zeros(3,1); [0; elev_deg; 90]*pi/180; zeros(3,1)];
time = 0:0.01:60;

[t_RK4, x_RK4] = int_RK4(@flight_6dof, time, init_state, @htg_event_flight);
alt = -x_RK4(:, 3);

%% 지표
res = struct();
res.m_prop = m_prop;
res.t_burn = tb(end);
res.I_total = trapz(tb, Fb);
res.F_mean = res.I_total / max(res.t_burn, eps);

[res.apogee, i_apo] = max(alt);
res.t_apogee = t_RK4(i_apo);

res.v_rail_exit = NaN; res.t_rail_exit = NaN;
i_exit = find(alt >= rail_h, 1);
if ~isempty(i_exit)
    res.v_rail_exit = norm(x_RK4(i_exit, 4:6));
    res.t_rail_exit = t_RK4(i_exit);
end

[~, i_bo] = min(abs(t_RK4 - res.t_burn));
res.burn_alt = alt(i_bo);
res.v_max = max(vecnorm(x_RK4(1:i_apo, 4:6), 2, 2));

fprintf('[%s] I=%.0f N.s (t_b %.2f s, F_avg %.0f N, m_prop %.3f kg)\n', ...
    config_base, res.I_total, res.t_burn, res.F_mean, m_prop);
fprintf('  레일 탈출 %.1f m/s (%.2f s) | 최대 고도 %.0f m (%.1f s) | 최대 속도 %.1f m/s\n', ...
    res.v_rail_exit, res.t_rail_exit, res.apogee, res.t_apogee, res.v_max);
end

function v = get_field(s, f, d)
if isfield(s, f), v = s.(f); else, v = d; end
end
