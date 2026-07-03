clear u unit; % 기존 변수 초기화 (선택 사항)
clc
close all
%% Ambient
u.amb.P = 1;
unit.amb.P = "bar"; % Pa, MPa, bar, atm, mmHg, psi

u.amb.T = 25;
unit.amb.T = "°C"; % K, °C, °F, C, F

u.amb.g = 9.80665;
unit.amb.g = "m/s^2"; % m/s^2, ft/s^2

%% Tank

u.tank.d = 90;
unit.tank.d = "mm"; % m, mm, cm, in

u.tank.h = 280;
unit.tank.h = "mm"; % m, mm, cm, in

u.tank.m = 1.3; % 탱크 내부 산화제 총 질량
unit.tank.m = "kg"; % kg, g, lb, oz

u.tank.T = 20;
unit.tank.T = "°C"; % K, °C, °F, C, F

u.tank.fluid = "N2O"; % N2O, CO2

%% Vent Port
% u.vent.A = 0.2;
% unit.vent.A = "mm^2"; % m^2, mm^2, cm^2, in^2

u.vent.d = 1/16;
unit.vent.d = "in"; % m, mm, cm, in

u.vent.model = "ICF(Isentropic Choked Flow)"; % ICF, CdA
u.vent.Cd = 0.1; % 토출계수
u.vent.mode = 1; % 0: 벤트포트 없음, 1: 벤트포트 있음

%% Injector
% u.inj.A = 0.2;
% unit.inj.A = "mm^2"; % m^2, mm^2, cm^2, in^2

u.inj.d = 1.4;
unit.inj.d = "mm"; % m, mm, cm, in

u.inj.n = 14; % 인젝터 개수
u.inj.Cd = 0.38; % 토출계수

u.inj.L = 7; % 인젝터 플레이트 두께
unit.inj.L = "mm"; % m, mm, cm, in

u.inj.model_LiqFeed = "NHNE(Non-Homogeneous Non-Equilibrium Flow)"; % NHNE, CdA
u.inj.model_VapFeed = "ICF(Isentropic Choked Flow)"; % ICF, CdA

%% Sub injector
% u.subinj.A = 0.2;
% unit.subinj.A = "mm^2"; % m^2, mm^2, cm^2, in^2

u.subinj.d = 1.4;
unit.subinj.d = "mm"; % m, mm, cm, in

u.subinj.n = 14; % 인젝터 개수
u.subinj.Cd = 0.38; % 토출계수

u.subinj.L = 7; % 인젝터 플레이트 두께
unit.subinj.L = "mm"; % m, mm, cm, in

u.subinj.model_LiqFeed = "NHNE(Non-Homogeneous Non-Equilibrium Flow)"; % NHNE, CdA
u.subinj.model_VapFeed = "ICF(Isentropic Choked Flow)"; % ICF, CdA

u.subinj.mode = 1; % 0: 서브 인젝터 없음, 1: 서브 인젝터 있음

%% Fuel
u.fuel.card = "HDPE"; % HDPE, HTPB, Paraffin

% u.fuel.rho = 935;
% unit.fuel.rho = "kg/m^3"; % kg/m^3, g/cm^3, lb/ft^3

u.fuel.R = 7.5; %주의: 반지름 기준임.
unit.fuel.R = "mm"; % m, mm, cm, in

u.fuel.R_out = 40; % 주의: 반지름 기준임.
unit.fuel.R_out = "mm"; % 외경 단위 추가 (내경과 동일한 단위 사용)

u.fuel.L = 230;
unit.fuel.L = "mm"; % m, mm, cm, in

u.fuel.N = 7;
u.fuel.a = 3.461*1e-2;
u.fuel.n = 0.48;

% u.fuel.N = 7;
% u.fuel.a = 0.01;
% u.fuel.n = 0.83;

u.fuel.model = "aGn"; % 사용할 그레인 후퇴율 모델 선택 (현재는 "aGn"만 유효)

%% Combustion Chamber
u.comb.eta = 0.7; % 특성속도 효율 (0~1)

u.comb.R_comb = 35; % 주의: 연소실 반경임.
unit.comb.R_comb = "mm"; % m, mm, cm, in

u.comb.L_comb = 230; % 연소실 (그레인 위치) 길이
unit.comb.L_comb = "mm"; % m, mm, cm, in

% Pre-Chamber Dimensions
u.comb.D_pre_chamber = 66; % Pre-Chamber 직경
unit.comb.D_pre_chamber = "mm"; % m, mm, cm, in
u.comb.L_pre_chamber = 33; % Pre-Chamber 길이
unit.comb.L_pre_chamber = "mm"; % m, mm, cm, in

% Post-Chamber Dimensions
u.comb.D_post_chamber = 66; % Post-Chamber 직경
unit.comb.D_post_chamber = "mm"; % m, mm, cm, in
u.comb.L_post_chamber = 66; % Post-Chamber 길이
unit.comb.L_post_chamber = "mm"; % m, mm, cm, in

%% Nozzle
u.nozzle.Dt = 17;
unit.nozzle.Dt = "mm"; % m, mm, cm, in

u.nozzle.De = 35;
unit.nozzle.De = "mm"; % m, mm, cm, in

% Nozzle Converging Section Parameters
u.nozzle.Dc = 66; % 노즐 수축부 입구 직경 (연소실 직경과 동일하게 설정)
unit.nozzle.Dc = "mm"; % m, mm, cm, in 
u.nozzle.theta_c = 30; % 노즐 수축부 수축각 (일반적으로 20~45도)
unit.nozzle.theta_c = "degree"; % degree, radian

% u.nozzle.eps = 4.88; % 면적비

u.nozzle.alpha = 15;
unit.nozzle.alpha = "degree"; % degree, radian

u.nozzle.theta_e = 15;
unit.nozzle.theta_e = "degree"; % degree, radian

u.nozzle.eta = 0.9; % 노즐 효율 (0~1)


%% Time
u.time.start = 0;
unit.time.start = "s"; % s, ms, min, hr

u.time.run = 10;
unit.time.run = "s"; % s, ms, min, hr   

u.time.stop = 30;   
unit.time.stop = "s"; % s, ms, min, hr

u.time.dt = 0.01;
unit.time.dt = "s"; % s, ms, min, hr

%% Simulation Settings
u.test.mode = 1; % 1: 연소 시험, 2: 분무 시험

%% Save Configuration
default_filename = 'default_config.mat';
prompt = sprintf('Enter filename to save (e.g., my_config) or press Enter for [%s]: ', default_filename);
user_input_name = input(prompt, 's'); % 사용자로부터 문자열 입력 받기

if isempty(user_input_name)
    config_filename_part = default_filename;
else
    % 입력된 이름에 .mat 확장자가 없으면 추가
    if ~endsWith(user_input_name, '.mat', 'IgnoreCase', true)
        config_filename_part = [user_input_name, '.mat'];
    else
        config_filename_part = user_input_name;
    end
end

% 실행 위치(cwd)와 무관하게 항상 이 스크립트가 있는 Config 폴더에 저장
config_filename = fullfile(fileparts(mfilename('fullpath')), config_filename_part);

fprintf('Saving input configuration to %s...\n', config_filename);
try
    save(config_filename, 'u', 'unit');
    fprintf('Input configuration saved successfully.\n');
catch ME
    fprintf('Error saving configuration: %s\n', ME.message);
end 