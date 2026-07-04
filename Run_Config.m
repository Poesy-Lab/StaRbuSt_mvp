function [y, x] = Run_Config(config_file_base)
%Run_Config  설정 파일 이름으로 시뮬레이션을 비대화형 실행 (Test_StaRbuSt의 헤드리스 판)
%   [y, x] = Run_Config('2026_nova_line_cold')
%   - Config/ 하위 폴더까지 재귀 검색하여 설정 로드 (Test_StaRbuSt와 동일)
%   - 실행 후 GenMatResults로 표준 .mat 출력 + 전체 이력 y를
%     Mat_Data/<이름>/<이름>_y.mat 로 저장 (TMS_Data 비교 스크립트가 사용)
%   - 플롯은 생성하지 않는다 (비교는 TMS_Data/Compare_2026_*.m 사용)

% 필요한 폴더들을 MATLAB 경로에 추가 (프로젝트 루트에서 실행 가정)
addpath(genpath('Input'));
addpath(genpath('Props'));
addpath(genpath('Components'));
addpath(genpath('System'));
addpath(genpath('Output'));
addpath(genpath('Config'));

config_file_to_load = [char(config_file_base), '.mat'];

% Config/ 하위 폴더까지 재귀 검색 (Test_StaRbuSt와 동일)
config_search = dir(fullfile('Config', '**', config_file_to_load));
if isempty(config_search)
    error('Run_Config:ConfigNotFound', 'Input configuration file not found: %s', config_file_to_load);
end
config_filepath = fullfile(config_search(1).folder, config_search(1).name);
fprintf('Loading input configuration from %s...\n', config_filepath);
load(config_filepath, 'u', 'unit');

%% Simulation
[x] = Input(u, unit);
[y] = System(x);

%% 표준 .mat 출력 + 전체 이력 저장
GenMatResults(y, char(config_file_base));
out_dir = fullfile('Mat_Data', char(config_file_base));
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
save(fullfile(out_dir, [char(config_file_base) '_y.mat']), 'y');
fprintf('Full history saved: %s\n', fullfile(out_dir, [char(config_file_base) '_y.mat']));

end
