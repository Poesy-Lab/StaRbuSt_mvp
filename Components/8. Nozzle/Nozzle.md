---
lastmod: 2025-04-30
tags:
  - 노즐
  - 추력계수
  - 추력
  - 비추력
Author: SRS 33기 박호진
---
# 소개
- `Nozzle.m`은 **노즐 형상에 따른 추력 계수, 추력 및 해수면 비추력**을 계산해주는 함수이다.
- 노즐 형상 보정 계수($\lambda$)는 콘 또는 벨노즐 형상에 따른 보정계수로 이를 추력에 반영하였다.
- 노즐 효율 또는 추력계수 효율($\eta_n$)은 유동 마찰 손실 및 경계층/점성 효과 등 비이상 효과가 반영된 인자로 이를 추력에 반영하였다.
	- 대체로 여러 실험에 따른 경험 인자이다.
- 추력 계수 및 추력식의 연소압은 이미 특성속도 효율(또는 연소효율, $\eta_{c^*}$)이 반영되어 있다고 가정한다.

# Input
| 명칭                 | 기호            | 입력 변수           | 비고                       |
| ------------------ | ------------- | --------------- | -------------------------- |
| 연소압                | $p_c$         | x.comb.P        | [Pa]                       |
| OF비                | $\text{OF}$   | x.comb.OF       |                            |
| 노즐 면적비             | $\varepsilon$ | x.nozzle.eps    |                            |
| 주위 압력 (또는 대기 압력)   | $p_a$         | x.amb.P         | [Pa]                       |
| CEA 추진제 객체         | -             | x.cea           | 추진제 조합에 대한 CEA 객체      |
| 노즐 형상 보정 계수        | $\lambda$     | x.nozzle.lambda |                            |
| 노즐 효율 (또는 추력계수 효율) | $\eta_n$      | x.nozzle.eta    | (`eta_n`으로 코드 수정됨)    |
| 노즐 목 면적            | $A_t$         | x.nozzle.At     | [m^2]                      |

```MATLAB
Pc = x.comb.P;
OF = x.comb.OF;
eps = x.nozzle.eps;
Pa = x.amb.P;
cea = x.cea;
lambda = x.nozzle.lambda;
eta_n = x.nozzle.eta;
At = x.nozzle.At;
```

# System
- 추력 계수 계산 (CEA 파이썬 라이브러리는 기본적으로 Imperial 단위계 이용)
  - RocketCEA의 `get_PambCf` 함수는 다음 값들을 반환합니다: `(Cf_Pe_eq_Pamb, CFamb, Mode_string)`
  - 여기서 `CFamb`는 주어진 주위 압력 `Pamb`에 대한 실제 추력계수입니다.
$$
C_F = C_{F,amb,\text{CEA}}(p_c, \text{OF}, \varepsilon, p_{a})
$$
- 노즐 출구 압력($P_e$) 및 작동 모드(`Mode`)는 `Mode_string`에서 추출됩니다.
```MATLAB
Pc_psia = Pc / 6894.757; % psia
Pa_psia = Pa / 6894.757; % psia

Cf = NaN; % Initialize output
F = NaN;
Isp_sl = NaN; % Initialize Sea Level Isp output
Mode = "Error"; % Initialize Mode output
Pe_Pa = NaN;    % Initialize Exit Pressure (Pa) output
% Pt_Pa 는 아래에서 초기화 됩니다.

if isfinite(Pc_psia) && Pc_psia > 0 && isfinite(OF) && OF >= 0 && isfinite(Pa_psia) && Pa_psia >= 0 && ~isempty(cea) % Pa_psia >= 0 for vacuum case
    % --- Calculate Thrust Coefficient (Cf) and Exit Conditions --- 
    try
        % Call get_PambCf using pyargs for keyword arguments
        Cf_cea_result = cea.get_PambCf(pyargs('Pc', Pc_psia, 'MR', OF, 'eps', eps, 'Pamb', Pa_psia)); 
        
        Cf_calc = double(Cf_cea_result(2));     % Use CFamb (Actual Thrust Coefficient for given Pamb)
        Mode_full_string = string(Cf_cea_result(3)); % Mode string with Pe info
        
        if isfinite(Cf_calc) % Check if CEA Cf calculation was successful
            Cf = Cf_calc;
            F = lambda * eta_n * Cf * Pc * At; 
            
            % --- Extract Exit Pressure (Pe) and Mode Name from Mode_full_string ---
            if ~isempty(Mode_full_string)
                pe_match = regexp(Mode_full_string, '(?:Pe|Pexit|Psep)\s*=\s*([\d.]+)', 'tokens', 'once');
                if ~isempty(pe_match)
                    Pe_psi = str2double(pe_match{1});
                    if isfinite(Pe_psi), Pe_Pa = Pe_psi * 6894.757; end
                end
                mode_match = regexp(Mode_full_string, '^(\w+)', 'tokens', 'once');
                if ~isempty(mode_match), Mode = string(mode_match{1}); end
            end
        else
            Mode = "CEA Error - Invalid Cf";
        end
    catch ME
        Mode = "CEA Error - Call Failed";
    end

    % 해수면 비추력 계산 (입력된 Pa_psia 기준)
    try
        Isp_sl_cea_result = cea.estimate_Ambient_Isp(pyargs('Pc', Pc_psia, 'MR', OF, 'eps', eps, 'Pamb', Pa_psia)); 
        Isp_sl_calc = double(Isp_sl_cea_result(1));
        if isfinite(Isp_sl_calc), Isp_sl = lambda * eta_n * Isp_sl_calc; end
    catch ME
        % Isp_sl remains NaN
    end
    
    % 노즐 목 압력 계산
    Pt_Pa = NaN; % Initialize Nozzle Throat Pressure (Pa)
    try
        Pc_ov_Pt_result = cea.get_Throat_PcOvPe(pyargs('Pc', Pc_psia, 'MR', OF));
        Pc_ov_Pt = double(Pc_ov_Pt_result);
        if isfinite(Pc_ov_Pt) && Pc_ov_Pt > 0
            P_throat_psia = Pc_psia / Pc_ov_Pt;
            Pt_Pa = P_throat_psia * 6894.757;
        end
    catch ME_ThroatPressure
        % Pt_Pa remains NaN
    end
else
    Mode = "Invalid Inputs";
end
```

- 추력 계산
$$
F = \lambda \cdot \eta_{n} \cdot C_F \cdot p_c \cdot A_t
$$
```MATLAB
F = lambda * eta_n * Cf * Pc * At;
```

- **해수면 비추력 계산**
  - 코드에서는 `estimate_Ambient_Isp` 호출 시 입력받은 실제 주위압력 `Pa_psia`를 사용합니다.

# Output
| 명칭          | 기호        | 출력 변수         | 비고 | 
| ----------- | --------- | ------------- | ---- | 
| 추력 계수       | $C_F$     | x.nozzle.Cf   | CFamb - 실제 주위 조건에 대한 추력계수 | 
| 추력          | $F$       | x.nozzle.F    | [N]  | 
| 해수면 비추력    | $I_{sp,sl}$ | x.nozzle.Isp_sl | [s] (실제 주위 압력 `Pa` 기준) | 
| 노즐 작동 모드   | $\text{Mode}$ | x.nozzle.Mode | 예: "OverExpanded", "UnderExpanded", "Frozen", "Shifting" 등 | 
| 노즐 출구 압력   | $P_e$     | x.nozzle.Pe   | [Pa] | 
| 노즐 목 압력    | $P_t$     | x.nozzle.Pt   | [Pa] |

```MATLAB
x.nozzle.Cf = Cf;
x.nozzle.F = F;
x.nozzle.Isp_sl = Isp_sl;
x.nozzle.Mode = Mode;
x.nozzle.Pe = Pe_Pa;
x.nozzle.Pt = Pt_Pa;
```

# 전체 코드
```MATLAB
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
        warning('Nozzle:CEA_ThroatPressure_Error', 'Error calling CEA get_Throat_PcOvPe for Pc=%.2f psia, OF=%.2f: %s', Pc_psia, OF, ME_ThroatPressure.message);
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
```
