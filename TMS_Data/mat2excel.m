%% .mat 파일을 .xlsx 파일로 변환하는 스크립트
%
% 이 스크립트는 지정된 폴더 및 그 하위 폴더에서 .mat 파일을 검색하여
% 사용자에게 목록을 보여주고, 선택된 파일을 Excel 파일로 변환합니다.
% .mat 파일 내의 각 변수는 Excel 파일의 별도 시트로 저장됩니다.

clear; clc; close all;

%% 1. 사용자 설정
% .mat 파일을 검색할 경로를 지정합니다.
target_dir = 'C:\Users\sitra\Desktop\Projects\2상 유동 시뮬레이션\StaRbuSt-Simulatrion(MATLAB)\TMS_Data\TMS_Data';

fprintf('지정된 경로: %s\n\n', target_dir);

if ~isfolder(target_dir)
    error('지정된 폴더를 찾을 수 없습니다: %s\n경로를 확인해주세요.', target_dir);
end

%% 2. .mat 파일 검색
fprintf('.mat 파일을 검색 중입니다...\n');
mat_files = dir(fullfile(target_dir, '**', '*.mat'));

if isempty(mat_files)
    error('.mat 파일을 "%s" 및 하위 폴더에서 찾을 수 없습니다.', target_dir);
end

%% 3. 사용자에게 파일 선택 요청
fprintf('%d개의 .mat 파일을 찾았습니다:\n', length(mat_files));
for i = 1:length(mat_files)
    fprintf('[%d] %s\n', i, fullfile(mat_files(i).folder, mat_files(i).name));
end

selected_idx = 0;
while selected_idx == 0
    try
        reply = input('\n변환할 파일의 번호를 입력하세요: ', 's');
        num = str2double(reply);
        if ~isnan(num) && num >= 1 && num <= length(mat_files)
            selected_idx = num;
        else
            fprintf('오류: 1부터 %d 사이의 숫자를 입력해주세요.\n', length(mat_files));
        end
    catch ME
        fprintf('잘못된 입력입니다. 다시 시도해주세요. 오류: %s\n', ME.message);
    end
end

selected_file_info = mat_files(selected_idx);
full_mat_path = fullfile(selected_file_info.folder, selected_file_info.name);
fprintf('\n선택된 파일: %s\n', full_mat_path);

%% 4. .mat 파일 로드 및 Excel로 변환
fprintf('파일을 변환하는 중...\n');

try
    % .mat 파일의 변수들을 구조체로 불러오기
    data_struct = load(full_mat_path);
    
    % 저장할 Excel 파일 경로 설정 (원본 .mat 파일과 같은 위치)
    [mat_dir, mat_name, ~] = fileparts(full_mat_path);
    excel_filename = [mat_name, '.xlsx'];
    full_excel_path = fullfile(mat_dir, excel_filename);
    
    % .mat 파일 내의 변수들 이름 가져오기
    variable_names = fieldnames(data_struct);
    
    if isempty(variable_names)
        warning('.mat 파일에 변환할 변수가 없습니다.');
        return;
    end
    
    % 기존 Excel 파일이 있다면 삭제하여 덮어쓰기 준비
    if exist(full_excel_path, 'file')
        delete(full_excel_path);
        fprintf('기존 Excel 파일을 삭제했습니다: %s\n', excel_filename);
    end

    % 각 변수를 별도의 시트로 저장
    for i = 1:length(variable_names)
        var_name = variable_names{i};
        data_to_write = data_struct.(var_name);
        
        % 시트 이름으로 사용할 수 없는 문자 제거 (최대 31자)
        % 구버전 MATLAB과의 호환성을 위해 'MaxLength' 옵션을 사용하지 않고 수동으로 길이를 조절합니다.
        sheet_name = matlab.lang.makeValidName(var_name, 'ReplacementStyle', 'delete');
        if length(sheet_name) > 31
           sheet_name = sheet_name(1:31);
        end
        
        if isempty(sheet_name)
            sheet_name = ['Sheet', num2str(i)];
        end
 
        fprintf('  - 변수 "%s"를 시트 "%s"에 쓰는 중...\n', var_name, sheet_name);
        
        % 변수 타입에 따라 다른 쓰기 함수 사용
        try
            if istable(data_to_write)
                writetable(data_to_write, full_excel_path, 'Sheet', sheet_name);
            elseif isnumeric(data_to_write) || islogical(data_to_write)
                writematrix(data_to_write, full_excel_path, 'Sheet', sheet_name);
            elseif iscell(data_to_write)
                writecell(data_to_write, full_excel_path, 'Sheet', sheet_name);
            else
                fprintf('    -> 경고: 변수 "%s"의 타입은 Excel에 쓸 수 없습니다. 건너뜁니다.\n', var_name);
            end
        catch write_error
             fprintf('    -> 오류: 변수 "%s"를 시트 "%s"에 쓰는 중 에러 발생. 건너뜁니다. (%s)\n', var_name, sheet_name, write_error.message);
        end
    end
    
    fprintf('\n변환 완료!\n');
    fprintf('Excel 파일이 다음 위치에 저장되었습니다:\n  %s\n', full_excel_path);
    
catch ME
    error('파일 변환 중 오류가 발생했습니다: %s\n오류 메시지: %s', full_mat_path, ME.message);
end
