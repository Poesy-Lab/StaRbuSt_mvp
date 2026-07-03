function [x] = Nozzle(x)
%% Input
Pc = x.comb.P;
OF = x.comb.OF;
eps = x.nozzle.eps;
Pa = x.amb.P;
cea = x.cea;
lambda = x.nozzle.lambda;
eta_n = x.nozzle.eta; % 변수명 eta -> eta_n 으로 수정 (Markdown 내용과 일치)
At = x.nozzle.At;

%% System
Pc_psia = Pc / 6894.757; % psia
Pa_psia = Pa / 6894.757; % psia

Cf = NaN; % Initialize output
F = NaN;
Isp_sl = NaN; % Initialize Sea Level Isp output
Mode = "Error"; % Initialize Mode output
Pe_Pa = NaN;    % Initialize Exit Pressure (Pa) output

% Check if inputs for CEA are valid
if isfinite(Pc_psia) && Pc_psia > 0 && isfinite(OF) && OF >= 0 && isfinite(Pa_psia) && Pa_psia >= 0 && ~isempty(cea) % Pa_psia >= 0 for vacuum case
    % --- Calculate Thrust Coefficient (Cf) and Exit Conditions --- 
    try
        % Call get_PambCf using pyargs for keyword arguments
        Cf_cea_result = cea.get_PambCf(pyargs('Pc', Pc_psia, 'MR', OF, 'eps', eps, 'Pamb', Pa_psia)); 
        
        % Extract results (MATLAB uses 1-based indexing)
        % Cf_cea_result(1): CF assuming Pe=Pamb (from CEA)
        % Cf_cea_result(2): CFamb - Actual Cf for the given Pamb (from RocketCEA)
        % Cf_cea_result(3): Mode string
        Cf_calc = double(Cf_cea_result(2));     % Use CFamb (Actual Thrust Coefficient for given Pamb)
        Mode_full_string = string(Cf_cea_result(3)); % Mode string with Pe info (Index 2 in Python)
        
        if isfinite(Cf_calc) % Check if CEA Cf calculation was successful
            Cf = Cf_calc; % Use CFamb for output and thrust calculation
            F = lambda * eta_n * Cf * Pc * At; % Thrust calculation using CFamb
            
            % --- Extract Exit Pressure (Pe) from Mode_full_string ---
            if ~isempty(Mode_full_string)
                pe_match = regexp(Mode_full_string, '(?:Pe|Pexit|Psep)\s*=\s*([\d.]+)', 'tokens', 'once');
                if ~isempty(pe_match)
                    Pe_psi = str2double(pe_match{1});
                    if isfinite(Pe_psi)
                       Pe_Pa = Pe_psi * 6894.757; % Convert psi to Pa
                    else
                       warning('Nozzle:PeConversionFailed', 'Failed to convert extracted Pe value (%s) to a number.', pe_match{1});
                       Pe_Pa = NaN; % Explicitly set NaN
                    end
                else
                    % warning('Nozzle:PePatternNotFound', 'Pe pattern not found in Mode string: "%s"', Mode_full_string);
                    Pe_Pa = NaN; % Explicitly set NaN
                end
            else
                warning('Nozzle:EmptyModeStringPe', 'CEA Mode string is empty, cannot extract Pe.');
                Pe_Pa = NaN; % Explicitly set NaN
            end
            % --- End Pe Extraction ---

            % --- Extract Mode Name from Mode_full_string ---
            if ~isempty(Mode_full_string)
                mode_match = regexp(Mode_full_string, '^(\w+)', 'tokens', 'once');
                if ~isempty(mode_match)
                    Mode = string(mode_match{1});
                else
                    warning('Nozzle:ModePatternNotFound', 'Mode name pattern not found in Mode string: "%s"', Mode_full_string);
                    Mode = "Extract Failed"; % Indicate extraction failure
                end
            else
                 warning('Nozzle:EmptyModeStringName', 'CEA Mode string is empty, cannot extract Mode name.');
                 Mode = "Empty String";
            end
            % --- End Mode Extraction ---
            
        else % Cf_calc is NaN or Inf
            warning('Nozzle:InvalidCEA_Cf', 'CEA get_PambCf returned non-finite Cf (%.4e) for Pc=%.2f, OF=%.2f, eps=%.1f, Pamb=%.2f', Cf_calc, Pc_psia, OF, eps, Pa_psia);
            Cf = NaN; % Ensure Cf is NaN
            F = NaN;  % Ensure F is NaN
            Mode = "CEA Error - Invalid Cf";
            Pe_Pa = NaN; % Explicitly set Pe NaN
        end
    catch ME
        warning('Nozzle:CEACfError', 'Error calling CEA get_PambCf for Pc=%.2f, OF=%.2f: %s', Pc_psia, OF, ME.message);
        Cf = NaN; % Ensure Cf is NaN
        F = NaN;  % Ensure F is NaN
        Mode = "CEA Error - Call Failed";
        Pe_Pa = NaN; % Explicitly set Pe NaN
    end

    % --- Calculate Sea Level Specific Impulse (Isp_sl) --- 
    try
        % Call estimate_Ambient_Isp using pyargs
        Isp_sl_cea_result = cea.estimate_Ambient_Isp(pyargs('Pc', Pc_psia, 'MR', OF, 'eps', eps, 'Pamb', Pa_psia)); 
        Isp_sl_calc = double(Isp_sl_cea_result(1)); % Isp 값 추출 (이론값)

        if isfinite(Isp_sl_calc)
            Isp_sl = lambda * eta_n * Isp_sl_calc; % Apply efficiencies to get actual Isp_sl
        else
            warning('Nozzle:InvalidCEA_Isp', 'CEA estimate_Ambient_Isp returned non-finite Isp_sl for Pc=%.2f, OF=%.2f, eps=%.1f, Pamb=%.2f', Pc_psia, OF, eps, Pa_psia); 
            % Isp_sl remains NaN
        end
    catch ME
        warning('Nozzle:CEAIspError', 'Error calling CEA estimate_Ambient_Isp for Pc=%.2f, OF=%.2f: %s', Pc_psia, OF, ME.message);
        % Isp_sl remains NaN
    end

    % --- Calculate Nozzle Throat Pressure (Pt) --- 
    Pt_Pa = NaN; % Initialize Nozzle Throat Pressure (Pa)
    try
        Pc_ov_Pt_result = cea.get_Throat_PcOvPe(pyargs('Pc', Pc_psia, 'MR', OF));
        Pc_ov_Pt = double(Pc_ov_Pt_result);

        if isfinite(Pc_ov_Pt) && Pc_ov_Pt > 0
            P_throat_psia = Pc_psia / Pc_ov_Pt;
            Pt_Pa = P_throat_psia * 6894.757; % Convert psi to Pa
        else
            warning('Nozzle:InvalidCEA_PcOvPt', 'CEA get_Throat_PcOvPe returned non-finite or non-positive ratio (%.4f) for Pc=%.2f psia, OF=%.2f', Pc_ov_Pt, Pc_psia, OF);
            % Pt_Pa remains NaN
        end
    catch ME_ThroatPressure
        warning('Nozzle:CEA_ThroatPressure_Error', ...
                'Error calling CEA get_Throat_PcOvPe for Pc=%.2f psia, OF=%.2f: %s', ...
                Pc_psia, OF, ME_ThroatPressure.message);
        % Pt_Pa remains NaN
    end
    % --- End Nozzle Throat Pressure Calculation ---

else
    warning('Nozzle:InvalidInputs', 'Skipping Nozzle CEA calculation due to invalid inputs: Pc=%.2f, OF=%.2f, Pa=%.2f, cea is empty=%d', Pc, OF, Pa, isempty(cea));
    % Cf, F, Isp_sl, Mode, Pe_Pa remain NaN/Error
    Mode = "Invalid Inputs"; 
end

%% Output
x.nozzle.Cf = Cf;       % CFamb - Actual Thrust Coefficient for ambient conditions
x.nozzle.F = F;         % Thrust (calculated with CFamb)
x.nozzle.Isp_sl = Isp_sl; % Output Sea Level Isp
x.nozzle.Mode = Mode;   % Nozzle Exit Condition Mode Name (e.g., UnderExpanded)
x.nozzle.Pe = Pe_Pa;    % Nozzle Exit Pressure (Pa)
x.nozzle.Pt = Pt_Pa;    % Nozzle Throat Pressure (Pa)

end 