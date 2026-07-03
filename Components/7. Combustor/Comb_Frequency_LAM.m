function [x] = Comb_Frequency_LAM(x)
%% Longitudinal Acoustic Mode Frequency Calculation
% Calculates the longitudinal acoustic mode frequency in the combustion chamber.

%% Input
% Get necessary inputs from the x structure
SoS_c = x.comb.SoS_c; % Speed of sound in chamber (m/s), calculated in Comb_param.m
L_pre = x.comb.L_pre_chamber; % Length of the pre-chamber (m)
L_comb = x.comb.L_comb;       % Length of the main combustion chamber (grain section) (m)
L_post = x.comb.L_post_chamber; % Length of the post-chamber (m)

%% System
% Calculate total effective acoustic length
L_m = L_pre + L_comb + L_post; % Total effective length for acoustic calculation (m)

% Initialize output
f_L1 = NaN; % 1st Longitudinal acoustic mode frequency (Hz)
f_L2 = NaN; % 2nd Longitudinal acoustic mode frequency (Hz)

% Check if inputs are valid
if isfinite(SoS_c) && SoS_c > 0 && isfinite(L_m) && L_m > 0
    % Calculate longitudinal acoustic mode frequencies
    % f_L = (n * c) / (2 * L_m)
    % where n = mode number, c = speed of sound, L_m = chamber length
    
    % 1st Mode (n=1)
    n_mode1 = 1;
    f_L1 = (n_mode1 * SoS_c) / (2 * L_m);
    
    % 2nd Mode (n=2)
    n_mode2 = 2;
    f_L2 = (n_mode2 * SoS_c) / (2 * L_m);
else
    if ~(isfinite(SoS_c) && SoS_c > 0)
        warning('CombFrequency:InvalidSoS', 'Invalid speed of sound (SoS_c = %.2f m/s) for frequency calculation.', SoS_c);
    end
    if ~(isfinite(L_m) && L_m > 0)
        warning('CombFrequency:InvalidLength', 'Invalid total effective chamber length (L_m = %.2f m) for frequency calculation. L_pre=%.2fm, L_comb=%.2fm, L_post=%.2fm', L_m, L_pre, L_comb, L_post);
    end
    % f_L1 and f_L2 remain NaN
end

%% Output
% Store the calculated frequencies in the x structure
x.comb.f_L1 = f_L1; % 1st Longitudinal acoustic mode frequency (Hz)
x.comb.f_L2 = f_L2; % 2nd Longitudinal acoustic mode frequency (Hz)

end
