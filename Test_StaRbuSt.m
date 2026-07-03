clc;
clear;
close all;

% --- 설정 파일 지정 ---
% config_file_to_load = 'yh16_1.mat'; % <<< 여기서 불러올 파일 이름 변경 <-- 기존 코드 주석 처리
% config_file_to_load = input('불러올 설정 파일 이름을 입력하세요 (.mat 확장자 포함): ', 's'); % <<< 사용자 입력 받도록 수정 <-- 이전 버전 주석 처리
config_file_base = input('불러올 설정 파일 이름을 입력하세요 (.mat 확장자 제외): ', 's'); % <<< 확장자 없이 입력받도록 수정
config_file_to_load = [config_file_base, '.mat']; % <<< 코드 내에서 확장자 추가
% --------------------

% 필요한 폴더들을 MATLAB 경로에 추가
addpath(genpath('Input'));
addpath(genpath('Props'));
addpath(genpath('Components')); % Add component functions to path
addpath(genpath('System'));     % Add system functions (like PreFeed) to path
addpath(genpath('Output'));     % Add output functions to path
addpath(genpath('Config'));     % Add config functions and file path

% --- Load Input Configuration ---
% Config/ 하위 폴더(2025_campaign, archive_2018-2024 등)까지 재귀 검색
config_search = dir(fullfile('Config', '**', config_file_to_load));
if ~isempty(config_search)
    config_filepath = fullfile(config_search(1).folder, config_search(1).name);
    fprintf('Loading input configuration from %s...\n', config_filepath);
    load(config_filepath, 'u', 'unit');
    fprintf('Input configuration loaded.\n');
else
    error('Input configuration file not found: %s\nPlease ensure the file exists under the Config directory (subfolders included) and Save_Input_Config.m was run.', config_file_to_load);
end
% --- End Load Input Configuration ---

%% Simulation
[x] = Input(u, unit);

%% Run Simulation
% addpath(genpath('Components')); % Add component functions to path - Moved to top
% addpath(genpath('System'));     % Add system functions (like PreFeed) to path - Moved to top

% [y] = System_new(x); % Call the main simulation function
[y] = System(x); % Call the main simulation function
% y = PostProcessInterpolateX1(y, x); % Apply post-processing interpolation (Commented out)

% Post-Processing: Plot Tank Results 
fprintf('\n--- Post-Processing ---\n');
try
    % Add Output directory and subdirectories to path
    % addpath(genpath('Output')); - Moved to top

    % Plot all results using the main plotting function
    PlotResults(y); % y contains the time vector (y.time)
    % GenMatResults(y) <-- 기존 호출 주석 처리
    GenMatResults(y, config_file_base) % <<< 수정된 함수 호출 (파일 기본 이름 전달)
catch ME
    warning('TestScript:PlottingFailed', 'Failed to generate plots: %s', ME.message);
end