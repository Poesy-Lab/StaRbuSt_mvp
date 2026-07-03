function [x_comb] = Init_Comb(u, unit) % unit은 사용되지 않지만 통일성을 위해 유지
%% 입력값 변환
% comb.R_comb, m (연소실 반경)
if isfield(u.comb, 'R_comb') % 사용자가 연소실 반경을 입력한 경우
    if isfield(unit, 'comb') && isfield(unit.comb, 'R_comb') % 단위 정보가 있는지 확인
        switch unit.comb.R_comb
            case "m"
                R_comb = u.comb.R_comb;
            case "mm"
                R_comb = u.comb.R_comb * 1e-3;
            case "cm"
                R_comb = u.comb.R_comb * 1e-2;
            case "in"
                R_comb = u.comb.R_comb * 0.0254;
            otherwise
                error("Init_Comb:InvalidUnitRcomb", "허용된 연소실 반경 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.comb.R_comb);
        end
    else
        warning('Init_Comb:MissingUnitRcomb', '연소실 반경 단위 (unit.comb.R_comb)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
        R_comb = u.comb.R_comb; % 단위 정보가 없으면 기본 단위(m)로 가정
    end
else
    error('Init_Comb:MissingRcomb', '연소실 반경 (u.comb.R_comb)이(가) 입력되지 않았습니다.');
    % 또는 필요에 따라 기본값을 설정할 수도 있습니다.
    % R_comb = defaultValue; 
end

% comb.L_comb, m (연소실 그레인 위치 길이)
if isfield(u.comb, 'L_comb')
    if isfield(unit, 'comb') && isfield(unit.comb, 'L_comb')
        switch unit.comb.L_comb
            case "m"
                L_comb_m = u.comb.L_comb;
            case "mm"
                L_comb_m = u.comb.L_comb * 1e-3;
            case "cm"
                L_comb_m = u.comb.L_comb * 1e-2;
            case "in"
                L_comb_m = u.comb.L_comb * 0.0254;
            otherwise
                error("Init_Comb:InvalidUnitLcomb", "허용된 연소실 길이 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.comb.L_comb);
        end
    else
        warning('Init_Comb:MissingUnitLcomb', '연소실 길이 단위 (unit.comb.L_comb)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
        L_comb_m = u.comb.L_comb; 
    end
else
    error('Init_Comb:MissingLcomb', '연소실 길이 (u.comb.L_comb)이(가) 입력되지 않았습니다.');
end

% comb.D_pre_chamber, m (Pre-Chamber 직경)
if isfield(u.comb, 'D_pre_chamber')
    if isfield(unit, 'comb') && isfield(unit.comb, 'D_pre_chamber')
        switch unit.comb.D_pre_chamber
            case "m"
                D_pre_chamber_m = u.comb.D_pre_chamber;
            case "mm"
                D_pre_chamber_m = u.comb.D_pre_chamber * 1e-3;
            case "cm"
                D_pre_chamber_m = u.comb.D_pre_chamber * 1e-2;
            case "in"
                D_pre_chamber_m = u.comb.D_pre_chamber * 0.0254;
            otherwise
                error("Init_Comb:InvalidUnitDprechamber", "허용된 Pre-Chamber 직경 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.comb.D_pre_chamber);
        end
    else
        warning('Init_Comb:MissingUnitDprechamber', 'Pre-Chamber 직경 단위 (unit.comb.D_pre_chamber)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
        D_pre_chamber_m = u.comb.D_pre_chamber;
    end
else
    error('Init_Comb:MissingDprechamber', 'Pre-Chamber 직경 (u.comb.D_pre_chamber)이(가) 입력되지 않았습니다.');
end

% comb.L_pre_chamber, m (Pre-Chamber 길이)
if isfield(u.comb, 'L_pre_chamber')
    if isfield(unit, 'comb') && isfield(unit.comb, 'L_pre_chamber')
        switch unit.comb.L_pre_chamber
            case "m"
                L_pre_chamber_m = u.comb.L_pre_chamber;
            case "mm"
                L_pre_chamber_m = u.comb.L_pre_chamber * 1e-3;
            case "cm"
                L_pre_chamber_m = u.comb.L_pre_chamber * 1e-2;
            case "in"
                L_pre_chamber_m = u.comb.L_pre_chamber * 0.0254;
            otherwise
                error("Init_Comb:InvalidUnitLprechamber", "허용된 Pre-Chamber 길이 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.comb.L_pre_chamber);
        end
    else
        warning('Init_Comb:MissingUnitLprechamber', 'Pre-Chamber 길이 단위 (unit.comb.L_pre_chamber)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
        L_pre_chamber_m = u.comb.L_pre_chamber;
    end
else
    error('Init_Comb:MissingLprechamber', 'Pre-Chamber 길이 (u.comb.L_pre_chamber)이(가) 입력되지 않았습니다.');
end

% comb.D_post_chamber, m (Post-Chamber 직경)
if isfield(u.comb, 'D_post_chamber')
    if isfield(unit, 'comb') && isfield(unit.comb, 'D_post_chamber')
        switch unit.comb.D_post_chamber
            case "m"
                D_post_chamber_m = u.comb.D_post_chamber;
            case "mm"
                D_post_chamber_m = u.comb.D_post_chamber * 1e-3;
            case "cm"
                D_post_chamber_m = u.comb.D_post_chamber * 1e-2;
            case "in"
                D_post_chamber_m = u.comb.D_post_chamber * 0.0254;
            otherwise
                error("Init_Comb:InvalidUnitDpostchamber", "허용된 Post-Chamber 직경 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.comb.D_post_chamber);
        end
    else
        warning('Init_Comb:MissingUnitDpostchamber', 'Post-Chamber 직경 단위 (unit.comb.D_post_chamber)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
        D_post_chamber_m = u.comb.D_post_chamber;
    end
else
    error('Init_Comb:MissingDpostchamber', 'Post-Chamber 직경 (u.comb.D_post_chamber)이(가) 입력되지 않았습니다.');
end

% comb.L_post_chamber, m (Post-Chamber 길이)
if isfield(u.comb, 'L_post_chamber')
    if isfield(unit, 'comb') && isfield(unit.comb, 'L_post_chamber')
        switch unit.comb.L_post_chamber
            case "m"
                L_post_chamber_m = u.comb.L_post_chamber;
            case "mm"
                L_post_chamber_m = u.comb.L_post_chamber * 1e-3;
            case "cm"
                L_post_chamber_m = u.comb.L_post_chamber * 1e-2;
            case "in"
                L_post_chamber_m = u.comb.L_post_chamber * 0.0254;
            otherwise
                error("Init_Comb:InvalidUnitLpostchamber", "허용된 Post-Chamber 길이 단위: m, mm, cm, in만 입력 가능. 입력된 단위: %s", unit.comb.L_post_chamber);
        end
    else
        warning('Init_Comb:MissingUnitLpostchamber', 'Post-Chamber 길이 단위 (unit.comb.L_post_chamber)가 지정되지 않았습니다. 기본 단위인 미터(m)로 가정합니다.');
        L_post_chamber_m = u.comb.L_post_chamber;
    end
else
    error('Init_Comb:MissingLpostchamber', 'Post-Chamber 길이 (u.comb.L_post_chamber)이(가) 입력되지 않았습니다.');
end

% 특별한 단위 변환 없음

x_comb = struct(); % 로컬 구조체 초기화

%% 상태량 초기화
x_comb.comb.eta = u.comb.eta; % 특성속도 효율 (0~1)
x_comb.comb.R_comb = R_comb; % m, 변환된 연소실 반경 저장
x_comb.comb.L_comb = L_comb_m; % m, 변환된 연소실 길이 저장
x_comb.comb.D_pre_chamber = D_pre_chamber_m; % m, 변환된 Pre-Chamber 직경 저장
x_comb.comb.L_pre_chamber = L_pre_chamber_m; % m, 변환된 Pre-Chamber 길이 저장
x_comb.comb.D_post_chamber = D_post_chamber_m; % m, 변환된 Post-Chamber 직경 저장
x_comb.comb.L_post_chamber = L_post_chamber_m; % m, 변환된 Post-Chamber 길이 저장

end 