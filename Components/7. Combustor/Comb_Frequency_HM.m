function [x] = Comb_Frequency_HM(x)
%% Helmholtz Resonance Frequency Calculations
% Calculates Helmholtz resonance frequencies for:
% 1. Pre-chamber volume with injector as neck (f_H_pre_chamber)
% 2. Overall chamber volume with injector as neck (f_H_overall)

%% Input
% Get necessary inputs from the x structure. 
% All dimensions are expected in meters, angles in radians, volumes in m^3.

% Speed of sound in chamber (m/s)
SoS_c = x.comb.SoS_c; 

% Pre-Chamber Dimensions (m)
D_pre_chamber = x.comb.D_pre_chamber;
L_pre_chamber = x.comb.L_pre_chamber;

% Grain Port Area (m^2) and Length (m) - Used to calculate V_grain_port
if isfield(x, 'fuel') && isfield(x.fuel, 'Ap') && isfinite(x.fuel.Ap) && x.fuel.Ap >= 0
    Ap_grain = x.fuel.Ap; % Total port area from Grain_aGn.m or similar
else
    error('Comb_Frequency_HM:MissingOrInvalidApGrain', '유효한 그레인 포트 단면적 (x.fuel.Ap)이 제공되지 않았습니다.');
end
if isfield(x, 'fuel') && isfield(x.fuel, 'L') && isfinite(x.fuel.L) && x.fuel.L > 0
    L_grain = x.fuel.L;   % Grain length
else
    error('Comb_Frequency_HM:MissingOrInvalidLGrain', '유효한 그레인 길이 (x.fuel.L)가 제공되지 않았습니다.');
end
V_grain_port = Ap_grain * L_grain; % Calculate Grain Port Volume (m^3)

% Post-Chamber Dimensions (m)
D_post_chamber = x.comb.D_post_chamber;
L_post_chamber = x.comb.L_post_chamber;

% Nozzle Converging Section Volume (m^3) - Assumed to be in x.nozzle.V_conv
if isfield(x, 'nozzle') && isfield(x.nozzle, 'V_conv') && isfinite(x.nozzle.V_conv) && x.nozzle.V_conv >= 0
    V_nozzle_conv = x.nozzle.V_conv;
else
    error('Comb_Frequency_HM:MissingOrInvalidVNozzleConv', '유효한 노즐 수축부 부피 (x.nozzle.V_conv)가 제공되지 않았습니다.');
end

% Injector (Neck) Dimensions (m)
L_neck_inj = x.inj.L; % Thickness of the injector plate (neck length)
D_neck_inj = x.inj.d; % Diameter of the injector orifice (neck diameter)

%% System
% Initialize outputs
f_H_pre_chamber = NaN; % Helmholtz frequency for pre-chamber
f_H_overall = NaN;     % Helmholtz frequency for overall chamber

% --- 1. Pre-Chamber Helmholtz Frequency Calculation ---
V_cavity_pre = (pi/4) * (D_pre_chamber^2) * L_pre_chamber;
A_neck_pre_calc = (pi/4) * (D_neck_inj^2);
L_eff_neck_pre_calc = L_neck_inj + 0.8 * D_neck_inj;

if isfinite(SoS_c) && SoS_c > 0 && ...
   isfinite(V_cavity_pre) && V_cavity_pre > 0 && ...
   isfinite(A_neck_pre_calc) && A_neck_pre_calc > 0 && ...
   isfinite(L_eff_neck_pre_calc) && L_eff_neck_pre_calc > 0
    
    denominator_sqrt_pre = V_cavity_pre * L_eff_neck_pre_calc;
    if denominator_sqrt_pre > 0
        f_H_pre_chamber = (SoS_c / (2*pi)) * sqrt(A_neck_pre_calc / denominator_sqrt_pre);
    else
        warning('CombFrequency_HM:InvalidDenominatorPre', 'Denominator in sqrt for pre-chamber is non-positive. Cannot calculate f_H_pre_chamber.');
    end
else
    warning('CombFrequency_HM:InvalidInputsPre', 'Invalid inputs for pre-chamber Helmholtz calculation.');
    % Add more specific warnings if needed here, similar to f_H_overall section
end

% --- 2. Overall Chamber Helmholtz Frequency Calculation ---
% Calculate individual volumes for total (some might be redundant if V_pre_chamber already calc)
V_pre_chamber_overall = (pi/4) * (D_pre_chamber^2) * L_pre_chamber; % Same as V_cavity_pre
V_post_chamber_overall = (pi/4) * (D_post_chamber^2) * L_post_chamber;

% Total Cavity Volume (m^3) for overall calculation
V_cavity_total = V_pre_chamber_overall + V_grain_port + V_post_chamber_overall + V_nozzle_conv;

% Injector Neck Area (m^2) - Same as A_neck_pre_calc
A_neck_overall_calc = (pi/4) * (D_neck_inj^2); 

% Effective Neck Length (m) - Same as L_eff_neck_pre_calc
L_eff_neck_overall_calc = L_neck_inj + 0.8 * D_neck_inj; 

% Check if inputs are valid for overall Helmholtz calculation
if isfinite(SoS_c) && SoS_c > 0 && ...
   isfinite(V_cavity_total) && V_cavity_total > 0 && ...
   isfinite(A_neck_overall_calc) && A_neck_overall_calc > 0 && ...
   isfinite(L_eff_neck_overall_calc) && L_eff_neck_overall_calc > 0

    denominator_sqrt_overall = V_cavity_total * L_eff_neck_overall_calc;

    if denominator_sqrt_overall > 0
        f_H_overall = (SoS_c / (2*pi)) * sqrt(A_neck_overall_calc / denominator_sqrt_overall);
    else
        warning('CombFrequency_HM:InvalidDenominatorOverall', 'Denominator in sqrt for overall calculation is non-positive. Cannot calculate f_H_overall.');
    end
else
    if ~(isfinite(SoS_c) && SoS_c > 0)
        warning('CombFrequency_HM:InvalidSoSOverall', 'Invalid speed of sound (SoS_c = %.2f m/s) for overall calculation.', SoS_c);
    end
    if ~(isfinite(V_cavity_total) && V_cavity_total > 0)
        warning('CombFrequency_HM:InvalidTotalCavityVolume', 'Invalid total cavity volume (V_cavity_total = %.2e m^3).', V_cavity_total);
        fprintf('Components: V_pre=%.2e, V_grain=%.2e, V_post=%.2e, V_nozzle_conv=%.2e\n', V_pre_chamber_overall, V_grain_port, V_post_chamber_overall, V_nozzle_conv);
    end
    if ~(isfinite(A_neck_overall_calc) && A_neck_overall_calc > 0)
        warning('CombFrequency_HM:InvalidNeckAreaOverall', 'Invalid neck area (A_neck = %.2e m^2). D_neck=%.2em', A_neck_overall_calc, D_neck_inj);
    end
    if ~(isfinite(L_eff_neck_overall_calc) && L_eff_neck_overall_calc > 0)
        warning('CombFrequency_HM:InvalidEffectiveNeckLengthOverall', 'Invalid effective neck length (L_eff_neck = %.2e m). L_neck=%.2em, D_neck=%.2em', L_eff_neck_overall_calc, L_neck_inj, D_neck_inj);
    end
end

%% Output
% Store the calculated frequencies in the x structure
x.comb.f_H_pre_chamber = f_H_pre_chamber; % Helmholtz frequency for pre-chamber (Hz)
x.comb.f_H_overall = f_H_overall;         % Helmholtz frequency for overall chamber (Hz)

end
