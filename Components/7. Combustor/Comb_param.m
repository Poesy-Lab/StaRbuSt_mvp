function [x] = Comb_param(x)
%% Input
% 연소실 압력, O/F비, CEA 객체는 x.comb 또는 x에서, 노즐 팽창비는 x.nozzle에서 가져옵니다.
Pc = x.comb.P;
OF = x.comb.OF;
eps = x.nozzle.eps; % 노즐 팽창비는 노즐 모듈의 파라미터를 사용
fac_CR = x.comb.fac_CR; % 수축비 (Contraction Ratio) from Comb_Itercalc
cea = x.cea;

%% System
Pc_psia = Pc / 6894.757; % psia

% Initialize outputs
mw = NaN;       % Initialize Chamber Molecular Weight (kg/kmol)
gamma = NaN;    % Initialize Chamber Specific Heat Ratio
rho_c = NaN;    % Initialize Chamber Density (kg/m^3)
SoS_c = NaN;    % Initialize Chamber Speed of Sound (m/s)
R_specific = NaN; % Initialize Specific Gas Constant (J/(kg*K))
Mach_c = NaN;     % Initialize Chamber Mach Number
Vc = NaN;         % Initialize Chamber Gas Velocity (m/s)

% Check if inputs for CEA are valid
% eps (팽창비)는 get_Chamber_MolWt_gamma 및 get_Chamber_Density 함수에서 사용되므로 유효성 검사에 포함합니다.
if isfinite(Pc_psia) && Pc_psia > 0 && isfinite(OF) && OF >= 0 && isfinite(eps) && eps > 0 && ~isempty(cea)
    % --- Calculate Chamber Molecular Weight and Specific Heat Ratio ---
    try
        chamber_props = cea.get_Chamber_MolWt_gamma(pyargs('Pc', Pc_psia, 'MR', OF, 'eps', eps));
        mw_lbm_per_lbmole = double(chamber_props{1}); % Original value in lbm/lbmole
        gamma_temp_val = double(chamber_props{2}); % dimensionless
        mw_temp = mw_lbm_per_lbmole; 
        if isfinite(mw_temp) && mw_temp > 0 && isfinite(gamma_temp_val) && gamma_temp_val > 0
            mw = mw_temp; 
            gamma = gamma_temp_val;
        else
            warning('CombParam:InvalidCEA_ChamberProps', ...
                    'CEA get_Chamber_MolWt_gamma returned non-finite/non-positive mw (%.2f kg/kmol) or gamma (%.2f) for Pc=%.2f, OF=%.2f, eps=%.1f', ...
                    mw_temp, gamma_temp_val, Pc_psia, OF, eps);
        end
    catch ME_ChamberProps
        warning('CombParam:CEA_ChamberProps_Error', ...
                'Error calling CEA get_Chamber_MolWt_gamma for Pc=%.2f, OF=%.2f, eps=%.1f: %s', ...
                Pc_psia, OF, eps, ME_ChamberProps.message);
    end

    % --- Calculate Chamber Density ---
    try
        rho_lbm_cuft = cea.get_Chamber_Density(pyargs('Pc', Pc_psia, 'MR', OF, 'eps', eps));
        rho_c_temp_unconverted = double(rho_lbm_cuft); 
        rho_c_temp = rho_c_temp_unconverted * 16.0184634; % kg/m^3
        if isfinite(rho_c_temp) && rho_c_temp > 0
            rho_c = rho_c_temp;
        else
            warning('CombParam:InvalidCEA_ChamberDensity', ...
                    'CEA get_Chamber_Density returned non-finite/non-positive rho_c (%.2f kg/m^3) for Pc=%.2f, OF=%.2f, eps=%.1f', ...
                    rho_c_temp, Pc_psia, OF, eps);
        end
    catch ME_ChamberDensity
        warning('CombParam:CEA_ChamberDensity_Error', ...
                'Error calling CEA get_Chamber_Density for Pc=%.2f, OF=%.2f, eps=%.1f: %s', ...
                Pc_psia, OF, eps, ME_ChamberDensity.message);
    end

    % --- Calculate Chamber Speed of Sound (Sonic Velocity) ---
    try
        SoS_c_fps = cea.get_Chamber_SonicVel(pyargs('Pc', Pc_psia, 'MR', OF, 'eps', eps));
        SoS_c_fps_double = double(SoS_c_fps); 
        SoS_c_temp = SoS_c_fps_double * 0.3048; % m/s
        if isfinite(SoS_c_temp) && SoS_c_temp > 0
            SoS_c = SoS_c_temp;
        else
            warning('CombParam:InvalidCEA_SonicVel', ...
                    'CEA get_Chamber_SonicVel returned non-finite/non-positive SoS_c (%.2f m/s) for Pc=%.2f, OF=%.2f, eps=%.1f', ...
                    SoS_c_temp, Pc_psia, OF, eps);
        end
    catch ME_SonicVel
        warning('CombParam:CEA_SonicVel_Error', ...
                'Error calling CEA get_Chamber_SonicVel for Pc=%.2f, OF=%.2f, eps=%.1f: %s', ...
                Pc_psia, OF, eps, ME_SonicVel.message);
    end

    % --- Calculate Chamber Mach Number ---
    if isfinite(fac_CR) && fac_CR > 0 % fac_CR은 Pc, OF와 함께 CEA 호출에 필요
        try
            Mach_c_val = cea.get_Chamber_MachNumber(pyargs('Pc', Pc_psia, 'MR', OF, 'fac_CR', fac_CR));
            Mach_c_double = double(Mach_c_val);
            if isfinite(Mach_c_double) % Mach number can be zero
                Mach_c = Mach_c_double;
            else
                warning('CombParam:InvalidCEA_MachNumber', ...
                        'CEA get_Chamber_MachNumber returned non-finite Mach_c (%.4f) for Pc=%.2f, OF=%.2f, fac_CR=%.2f', ...
                        Mach_c_double, Pc_psia, OF, fac_CR);
            end
        catch ME_MachNumber
            warning('CombParam:CEA_MachNumber_Error', ...
                    'Error calling CEA get_Chamber_MachNumber for Pc=%.2f, OF=%.2f, fac_CR=%.2f: %s', ...
                    Pc_psia, OF, fac_CR, ME_MachNumber.message);
        end
    else
        warning('CombParam:InvalidFacCRForMach', ...
                'Skipping Chamber Mach Number calculation due to invalid fac_CR (%.2f). It should be finite and positive.', fac_CR);
    end

else
    warning('CombParam:InvalidInputs', 'Skipping CombParam CEA calculation due to invalid inputs: Pc=%.2f Pa, OF=%.2f, eps=%.1f, fac_CR=%.2f, cea is empty=%d', Pc, OF, eps, fac_CR, isempty(cea));
    % mw, gamma, rho_c, SoS_c, R_specific, Mach_c, Vc remain NaN as initialized
end

% --- Calculate Specific Gas Constant ---
if isfinite(mw) && mw > 0 
    R_universal_J_kmol_K = 8314.46; 
    R_specific = R_universal_J_kmol_K / mw; 
else
    if ~(isfinite(mw) && mw > 0)
        warning('CombParam:InvalidMwForRspecific', 'Cannot calculate R_specific due to invalid mw (%.2f kg/kmol).', mw);
    end
end

% --- Calculate Chamber Gas Velocity ---
if isfinite(Mach_c) && isfinite(SoS_c)
    Vc = Mach_c * SoS_c;
    if ~(isfinite(Vc)) % Check if Vc calculation resulted in NaN (e.g. Inf * 0)
        warning('CombParam:VcCalculationInvalid', ...
                'Chamber gas velocity (Vc) calculation resulted in a non-finite value (Mach_c=%.4f, SoS_c=%.2f m/s). Setting Vc to NaN.', ...
                Mach_c, SoS_c);
        Vc = NaN; % Ensure Vc is NaN if calculation is problematic
    end
elseif isfinite(Pc_psia) && isfinite(OF) % Only warn if inputs were generally valid for other calcs
    if ~isfinite(Mach_c)
        warning('CombParam:SkippingVcMachInvalid', 'Skipping Vc calculation: Chamber Mach number (Mach_c) is not valid.');
    end
    if ~isfinite(SoS_c)
        warning('CombParam:SkippingVcSoSInvalid', 'Skipping Vc calculation: Chamber Speed of Sound (SoS_c) is not valid.');
    end
    % Vc remains NaN
end

%% Output
x.comb.mw = mw;       
x.comb.gamma = gamma;   
x.comb.rho_c = rho_c; 
x.comb.SoS_c = SoS_c; 
x.comb.R_specific = R_specific; 
x.comb.Mach_c = Mach_c;     % Chamber Mach Number
x.comb.Vc = Vc;             % Chamber Gas Velocity (m/s)

end
