% Output/GenMatResults.m

% function GenMatResults(y) <-- 기존 함수 정의 주석 처리
function GenMatResults(y, input_filename_base) % <<< 파일 기본 이름을 인수로 추가
%GenMatResults Generates .mat data files by calling component-specific generators.
%   Calls main data generation functions for each major component (e.g., Nozzle)
%   to save specific variables into .mat files using the input filename base.
%
%   Inputs:
%       y: Simulation results structure (must contain y.time and other data).
%       input_filename_base: Base name of the input config file (without .mat).
%   Output directory is fixed to 'Mat_Data'.

fprintf('\n--- Generating Simulation Result .mat Files (Base: %s) ---\n', input_filename_base);

% --- Setup Output Directory ---
output_dir = fullfile('Mat_Data', input_filename_base); % 실행(config)별 하위 폴더에 저장

% Create the output directory if it doesn't exist
if ~exist(output_dir, 'dir')
    try
        mkdir(output_dir);
        fprintf('Created output directory: %s\n', output_dir);
    catch ME
        warning('GenMatResults:DirCreationFailed', ...
            'Could not create output directory \'\'%s\'\': %s. Files will be saved in the current directory.', ...
            output_dir, ME.message);
        output_dir = '.'; % Save in current directory if creation fails
    end
end

% --- Tank Data ---
% Generates .mat file for Tank Pressure vs. Time.
if isfield(y, 'tank') && isfield(y.tank, 'P') && any(y.tank.P > 0)
    try
        fprintf('Generating Tank Data (P vs t)...\n');
        Time = y.time;
        Tank_Pressure = y.tank.P;
        
        output_filename = fullfile(output_dir, [input_filename_base, '_output_Tank_Pressure_vs_Time.mat']);
        save(output_filename, 'Time', 'Tank_Pressure');
        fprintf('  -> Saved to: %s\n', output_filename);
    catch ME
        warning('GenMatResults:TankDataFailed', 'Could not generate tank data: %s', ME.message);
    end
else
    fprintf('Skipping Tank Pressure .mat file generation: No data found.\n');
end


% --- Vent Port Data ---
% Placeholder: Add call to Gen_Vent_Data(y, output_dir) when created
% try
%     fprintf('Generating Vent Port Data...\n');
%     % Gen_Vent_Data(y, fullfile(output_dir, 'Vent_Data.mat')); % Example call
%     fprintf('Vent port data generated successfully.\n');
% catch ME
%     warning('GenMatResults:VentDataFailed', 'Could not generate vent port data: %s', ME.message);
% end

% --- Injector Data ---
% Generates .mat file for Injector Pressure vs. Time.
if isfield(y, 'inj') && isfield(y.inj, 'P') && any(y.inj.P > 0)
    try
        fprintf('Generating Injector Data (P vs t)...\n');
        Time = y.time;
        Injector_Pressure = y.inj.P;

        output_filename = fullfile(output_dir, [input_filename_base, '_output_Injector_Pressure_vs_Time.mat']);
        save(output_filename, 'Time', 'Injector_Pressure');
        fprintf('  -> Saved to: %s\n', output_filename);
    catch ME
        warning('GenMatResults:InjectorDataFailed', 'Could not generate injector data: %s', ME.message);
    end
else
    fprintf('Skipping Injector Pressure .mat file generation: No data found.\n');
end

% --- Grain Data ---
% Placeholder: Add call to Gen_Grain_Data(y, output_dir) when created
% try
%     fprintf('Generating Grain Data...\n');
%     % Gen_Grain_Data(y, fullfile(output_dir, 'Grain_Data.mat')); % Example call
%     fprintf('Grain data generated successfully.\n');
% catch ME
%     warning('GenMatResults:GrainDataFailed', 'Could not generate grain data: %s', ME.message);
% end

% --- Combustion Data ---
% Generates .mat file for Combustion Pressure vs. Time.
if isfield(y, 'comb') && isfield(y.comb, 'P') && any(y.comb.P > 0)
    try
        fprintf('Generating Combustion Data (P vs t)...\n');
        Time = y.time;
        Combustor_Pressure = y.comb.P;
        
        output_filename = fullfile(output_dir, [input_filename_base, '_output_Comb_Pressure_vs_Time.mat']);
        save(output_filename, 'Time', 'Combustor_Pressure');
        fprintf('  -> Saved to: %s\n', output_filename);
    catch ME
        warning('GenMatResults:CombDataFailed', 'Could not generate combustion pressure data: %s', ME.message);
    end
else
    fprintf('Skipping Combustion Pressure .mat file generation: No data found.\n');
end

% Calls Gen_Comb_Mdot_t to save mass flow rate vs time data
if isfield(y, 'comb') && isfield(y.comb, 'mdot') && any(y.comb.mdot > 0)
    try
        fprintf('Generating Combustion Data (mdot vs t)...\n');
        output_filename = fullfile(output_dir, [input_filename_base, '_output_Comb_Mdot_vs_Time.mat']);
        Gen_Comb_Mdot_t(y, output_filename); % Pass y and the full output path
    catch ME
        warning('GenMatResults:CombDataFailed', 'Could not generate combustion data: %s', ME.message);
    end
else
    fprintf('Skipping Combustion .mat file generation: No data found (likely Spray Test mode).\n');
end

% --- Nozzle Data ---
% Calls Gen_Nozzle_F_t to save thrust vs time data
if isfield(y, 'nozzle') && isfield(y.nozzle, 'F') && any(y.nozzle.F > 0)
    try
        fprintf('Generating Nozzle Data (F vs t)...\n');
        % output_filename = fullfile(output_dir, 'Nozzle_Thrust_vs_Time.mat'); <-- 기존 파일명 생성 주석 처리
        output_filename = fullfile(output_dir, [input_filename_base, '_output_Nozzle_Thrust_vs_Time.mat']); % <<< 입력 파일명 기반으로 수정
        Gen_Nozzle_F_t(y, output_filename); % Pass y and the full output path
        % fprintf is handled inside Gen_Nozzle_F_t
    catch ME
        warning('GenMatResults:NozzleDataFailed', 'Could not generate nozzle data: %s', ME.message);
    end
else
    fprintf('Skipping Nozzle .mat file generation: No data found (likely Spray Test mode).\n');
end

fprintf('--- .mat File Generation Complete ---\n\n');

end 