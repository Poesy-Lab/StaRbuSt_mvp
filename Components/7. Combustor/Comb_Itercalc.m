function [x] = Comb_Itercalc(x)
%% Combustion Chamber Calculations
% Calculates combustor properties, including a NEW combustion pressure (Pc)
% based on the input state (including the Pc from the previous iteration or initial guess).
% Assumes fuel mass flow rate (x.fuel.mdot) has already been calculated.

%% Input
mdot_ox = x.inj.mdot;
mdot_f = x.fuel.mdot; % PRE-CALCULATED by caller
Pc_input = x.comb.P; % Input Pc (previous iteration/initial guess)
cea = x.cea;
eta_cstar = x.comb.eta;
At = x.nozzle.At;

%% System
% Combustion Chamber Mass Flow Rate
mdot_p = mdot_f + mdot_ox;

% Calculate O/F Ratio (Simplified Logic)
OF = NaN; % Initialize OF
if isfinite(mdot_ox) && isfinite(mdot_f)
    if mdot_f > 1e-12 % Use tolerance instead of exact zero comparison
        OF = mdot_ox / mdot_f;
    elseif abs(mdot_f) <= 1e-12 % mdot_f is effectively zero
        if mdot_ox > 1e-12
            OF = Inf;
        else % Both mdot_f and mdot_ox are effectively zero
            OF = 0;
        end
    end % No explicit warning for mdot_f < 0, assume handled by isfinite
else
    warning('Comb:InvalidMassFlows', 'Cannot calculate OF due to non-finite mdot_ox (%.2f) or mdot_f (%.2f).', mdot_ox, mdot_f);
    % OF remains NaN
end

% Characteristic Velocity Calculation based on INPUT Pc
Pc_psia = Pc_input / 6894.757; % psia
cstar = NaN; % Initialize cstar

% Check if Inputs for CEA (Pc_psia, OF) are valid before calling CEA
if isfinite(OF) && OF >= 0 && isfinite(Pc_psia) && Pc_psia > 0
    try
        cstar_ft = cea.get_Cstar(pyargs('Pc', Pc_psia, 'MR', OF)); % ft/s
        cstar = double(cstar_ft * 0.3048); % m/s

        % Check if CEA output is valid
        if ~isfinite(cstar) || cstar <= 0
             warning('Comb:InvalidCEAOutput', 'CEA returned non-positive or non-finite c* (%.2f) for Pc=%.2f, OF=%.2f', cstar, Pc_psia, OF);
             cstar = NaN; % Ensure cstar is NaN if CEA output is invalid
        end

        % --- Add Combustion Temperature Calculation ---
        Tc_K = NaN; % Initialize combustion temperature in Kelvin
        if isfinite(cstar) % Attempt Tcomb only if cstar calculation was tried (and inputs were valid)
            try
                Tc_R = cea.get_Tcomb(pyargs('Pc', Pc_psia, 'MR', OF)); % Get Tcomb in Rankine
                Tc_K_temp = double(Tc_R) * (5/9); % Convert to Kelvin

                % Check if CEA Tcomb output is valid
                if isfinite(Tc_K_temp) && Tc_K_temp > 0
                    Tc_K = Tc_K_temp;
                else
                    warning('Comb:InvalidCEA_Tcomb', 'CEA returned non-positive or non-finite Tcomb (%.2f K) for Pc=%.2f, OF=%.2f', Tc_K_temp, Pc_psia, OF);
                    Tc_K = NaN;
                end
            catch ME_Tcomb
                warning('Comb:CEA_Tcomb_Error', 'CEA Tcomb calculation failed for Pc=%.2f psia, OF=%.2f: %s', Pc_psia, OF, ME_Tcomb.message);
                Tc_K = NaN; % Ensure Tc_K is NaN on error
            end
        end
        % --- End Combustion Temperature Calculation ---

    catch ME
        warning('Comb:CEAError', 'CEA c* calculation failed for Pc=%.2f psia, OF=%.2f: %s', Pc_psia, OF, ME.message);
        cstar = NaN; % Ensure cstar is NaN on error
    end
else
    warning('Comb:InvalidCEAInput', 'Skipping CEA c* and Tcomb calculation due to invalid OF (%.2f) or Pc_psia (%.2f).', OF, Pc_psia);
    cstar = NaN;
    Tc_K = NaN; % Also set Tc_K to NaN here
end

% Calculate NEW Combustion Pressure based on calculated cstar
Pc_calc = NaN; % Initialize calculated Pc
if isfinite(cstar) && cstar > 0 % Also check if cstar is positive
    Pc_calc = ( eta_cstar * cstar * mdot_p ) / At; % Pa
else
    Pc_calc = NaN; % Ensure Pc_calc is NaN if cstar is not valid
end

% --- Calculate Injector Pressure (Pinj) ---
Pinj = NaN; % Initialize Injector Pressure
fac_CR = NaN; % Initialize Contraction Ratio

if isfield(x, 'comb') && isfield(x.comb, 'R_comb') && isfinite(x.comb.R_comb) && x.comb.R_comb > 0 && ...
   isfinite(At) && At > 0 && isfinite(Pc_calc) && Pc_calc > 0 && isfinite(OF) && OF >= 0 && ~isempty(cea)

    Ac = pi * (x.comb.R_comb^2); % 연소실 단면적 (m^2)
    fac_CR = Ac / At; % 수축비 (Contraction Ratio)

    Pc_calc_psia = Pc_calc / 6894.757; % Pc_calc를 psia로 변환

    try
        Pinj_ov_Pcomb_result = cea.get_Pinj_over_Pcomb(pyargs('Pc', Pc_calc_psia, 'MR', OF, 'fac_CR', fac_CR));
        Pinj_ov_Pcomb = double(Pinj_ov_Pcomb_result);

        if isfinite(Pinj_ov_Pcomb) && Pinj_ov_Pcomb > 0
            Pinj = Pinj_ov_Pcomb * Pc_calc; % Pa (Pc_calc가 Pa 단위이므로 결과도 Pa)
        else
            warning('Comb:InvalidCEA_PinjRatio', 'CEA get_Pinj_over_Pcomb returned non-finite or non-positive ratio (%.4f) for Pc=%.2f psia, OF=%.2f, fac_CR=%.2f', Pinj_ov_Pcomb, Pc_calc_psia, OF, fac_CR);
            Pinj = NaN;
        end
    catch ME_Pinj
        warning('Comb:CEA_PinjError', 'CEA get_Pinj_over_Pcomb calculation failed for Pc=%.2f psia, OF=%.2f, fac_CR=%.2f: %s', Pc_calc_psia, OF, fac_CR, ME_Pinj.message);
        Pinj = NaN;
    end
else
    if ~(isfield(x, 'comb') && isfield(x.comb, 'R_comb') && isfinite(x.comb.R_comb) && x.comb.R_comb > 0)
        warning('Comb:InvalidRcomb', 'Skipping Pinj calculation: 연소실 반경 (x.comb.R_comb)이 유효하지 않습니다.');
    elseif ~(isfinite(At) && At > 0)
        warning('Comb:InvalidAt', 'Skipping Pinj calculation: 노즐 목 면적 (At)이 유효하지 않습니다.');
    elseif ~(isfinite(Pc_calc) && Pc_calc > 0)
        warning('Comb:InvalidPcForPinj', 'Skipping Pinj calculation: 계산된 연소실 압력 (Pc_calc)이 유효하지 않습니다.');
    elseif ~(isfinite(OF) && OF >= 0)
        warning('Comb:InvalidOFForPinj', 'Skipping Pinj calculation: 계산된 O/F 비율 (OF)이 유효하지 않습니다.');
    elseif isempty(cea)
        warning('Comb:MissingCEAForPinj', 'Skipping Pinj calculation: CEA 객체가 없습니다.');
    end
    % Pinj 와 fac_CR은 NaN으로 유지
end
% --- End Injector Pressure Calculation ---

%% Output
x.comb.mdot = mdot_p;
x.comb.OF = OF;
x.comb.cstar = cstar;
x.comb.P = Pc_calc; % Output the NEWLY CALCULATED Pc for this iteration
x.comb.T = Tc_K; % <<< Add calculated combustion temperature
x.comb.fac_CR = fac_CR; % Add calculated contraction ratio
x.comb.Pinj = Pinj;     % Add calculated injector pressure

end 