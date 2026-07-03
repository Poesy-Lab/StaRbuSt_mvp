function [x] = Comb_Frequency_HLFM(x)
%Comb_Frequency_HLFM Calculates the Hybrid Low Frequency Mode (HLFM)
%oscillation frequency.
%
% Formula based on:
%   f_HL = 0.48 * (2 + 1/(O/F)) * (G_ox * R_specific * T_comb) / (c_prime * L_grain * P_comb)
%
% Inputs:
%   x: Structure containing the current simulation state. Expected fields:
%       x.comb.OF       : Oxidizer to Fuel ratio (dimensionless)
%       x.comb.R_specific : Specific gas constant of combustion products (J/kg*K)
%       x.comb.T        : Combustion temperature (K)
%       x.comb.P        : Combustion chamber pressure (Pa)
%       x.fuel.Gox      : Oxidizer mass flux (kg/m^2-s)
%       x.fuel.L        : Grain length (m)
%
% Outputs:
%   x: Updated structure with:
%       x.comb.f_HL     : Calculated HLFM frequency (Hz)

%% Input Extraction and Validation
OF = NaN;
G_ox = NaN;
R_specific = NaN;
T_comb = NaN;
L_grain = NaN;
P_comb = NaN;

valid_inputs = true;

if isfield(x, 'comb')
    if isfield(x.comb, 'OF')
        OF = x.comb.OF;
    else
        warning('Comb_Frequency_HLFM:MissingOF', 'x.comb.OF not found.');
        valid_inputs = false;
    end
    if isfield(x.comb, 'R_specific')
        R_specific = x.comb.R_specific;
    else
        warning('Comb_Frequency_HLFM:MissingRspecific', 'x.comb.R_specific not found.');
        valid_inputs = false;
    end
    if isfield(x.comb, 'T')
        T_comb = x.comb.T;
    else
        warning('Comb_Frequency_HLFM:MissingTcomb', 'x.comb.T not found.');
        valid_inputs = false;
    end
    if isfield(x.comb, 'P')
        P_comb = x.comb.P;
    else
        warning('Comb_Frequency_HLFM:MissingPcomb', 'x.comb.P not found.');
        valid_inputs = false;
    end
else
    warning('Comb_Frequency_HLFM:MissingCombStruct', 'x.comb structure not found.');
    valid_inputs = false;
end

if isfield(x, 'fuel')
    if isfield(x.fuel, 'Gox')
        G_ox = x.fuel.Gox;
    else
        warning('Comb_Frequency_HLFM:MissingGox', 'x.fuel.Gox not found.');
        valid_inputs = false;
    end
    if isfield(x.fuel, 'L')
        L_grain = x.fuel.L;
    else
        warning('Comb_Frequency_HLFM:MissingLgrain', 'x.fuel.L not found.');
        valid_inputs = false;
    end
else
    warning('Comb_Frequency_HLFM:MissingFuelStruct', 'x.fuel structure not found.');
    valid_inputs = false;
end

%% Constants
coeff_fHL = 0.48;
c_prime = 2.050; % Boundary-layer delay time coefficient

%% Calculation
f_HL = NaN; % Initialize output frequency

if valid_inputs
    % Further check for calculation-specific invalid values (e.g., division by zero)
    if ~isfinite(OF) || OF == 0
        warning('Comb_Frequency_HLFM:InvalidOF', 'O/F ratio is non-finite or zero (%.2f). Cannot calculate f_HL.', OF);
    elseif ~isfinite(G_ox)
        warning('Comb_Frequency_HLFM:InvalidGox', 'Oxidizer mass flux (G_ox) is non-finite (%.2e). Cannot calculate f_HL.', G_ox);
    elseif ~isfinite(R_specific)
        warning('Comb_Frequency_HLFM:InvalidRspecific', 'Specific gas constant (R_specific) is non-finite (%.2f). Cannot calculate f_HL.', R_specific);
    elseif ~isfinite(T_comb) || T_comb <= 0 % Temperature should be positive in Kelvin
        warning('Comb_Frequency_HLFM:InvalidTcomb', 'Combustion temperature (T_comb) is non-finite or non-positive (%.2f K). Cannot calculate f_HL.', T_comb);
    elseif ~isfinite(L_grain) || L_grain <= 0
        warning('Comb_Frequency_HLFM:InvalidLgrain', 'Grain length (L_grain) is non-finite or non-positive (%.3f m). Cannot calculate f_HL.', L_grain);
    elseif ~isfinite(P_comb) || P_comb <= 0
        warning('Comb_Frequency_HLFM:InvalidPcomb', 'Combustion pressure (P_comb) is non-finite or non-positive (%.0f Pa). Cannot calculate f_HL.', P_comb);
    else
        term_OF = 2 + (1 / OF);
        numerator = G_ox * R_specific * T_comb;
        denominator = c_prime * L_grain * P_comb;

        if denominator == 0
            warning('Comb_Frequency_HLFM:DenominatorZero', 'Denominator in HLFM frequency calculation is zero. Cannot calculate f_HL.');
        else
            f_HL = coeff_fHL * term_OF * (numerator / denominator);
        end
    end
else
    warning('Comb_Frequency_HLFM:SkippingCalculation', 'Skipping HLFM frequency calculation due to missing input fields.');
end

%% Output
% Ensure x.comb structure exists before assigning the new field
if ~isfield(x, 'comb')
    x.comb = struct();
end
x.comb.f_HL = f_HL;

end
