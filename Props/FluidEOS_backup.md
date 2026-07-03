```matlab
classdef (Abstract) FluidEOS
	properties (Abstract, Constant)
		%--- 임계 및 유체 상수 ---
		Tc % 임계온도 [K]
		rhoc % 임계밀도 [kg/m^3]
		R % 기체 상수 [J/(kg·K)]
		fluid_state % 0=Non-Polar, 1=Polar
		
		%--- 이상 기체 헬름홀츠 계수 ---
		a1 % 이상 기체 헬름홀츠 a1
		a2 % 이상 기체 헬름홀츠 a2
		c0 % 이상 기체 헬름홀츠 c0
		c1 % 이상 기체 헬름홀츠 c1
		c2 % 이상 기체 헬름홀츠 c2
		v % Einstein Cp 모델 벡터 (1×5)
		u % Einstein Cp 모델 벡터 (1×5)
		
		%--- 잔류 헬름홀츠 계수 벡터 (1×12) ---
		n
	end
	
	methods
		function Helm = computeState(obj, T, rho)
			assert(T > 0 && rho > 0, 'T and rho must be positive.');
			Helm = HelmholtzEOS(obj, T, rho);
		end
		
		function Props = GetProps(obj, T, rho)
            tolerance = 1e-9; % Tolerance for density comparison

            %% System
            if rho <= 0 || T <= 0 || ~isreal(rho) || ~isreal(T)
                state = -1;
                % Assign NaNs to all properties in error state
                Props = obj.createNaNProps(); 
                Props.state = state;
                Props.T = T; % Keep original T and rho for debugging if needed
                Props.rho = rho;
                return; 
            end

            %% State Determination Logic (Revised)
            Helm = obj.computeState(T, rho); 
            P = Helm.P;
            u = Helm.u; s = Helm.s; h = Helm.h; cp = Helm.cp; cv = Helm.cv; c = Helm.c;

            % Determine State and Saturated Properties if applicable
            [rho_l, rho_v] = obj.satDensity(T);
            
            state = NaN; % Initialize state
            X = NaN;     % Initialize quality

            if isnan(rho_l) || isnan(rho_v) % Above critical temp or error
                if T > obj.Tc
                   state = 2; % Supercritical fluid treated as gas/vapor
                else
                   warning('FluidEOS:SatDensityNaN', 'satDensity returned NaN below Tc (T=%.2f K)', T);
                   state = -1; % Error state
                end
            elseif rho > rho_l * (1 + tolerance) % Compressed Liquid
                 state = 0;
            elseif rho < rho_v * (1 - tolerance) % Superheated Vapor
                 state = 2;
            else % Likely two-phase (or very close to saturation line)
                state = 1;
                X = (1/rho - 1/rho_l) / (1/rho_v - 1/rho_l); % Calculate quality
            end
            % --- End State Determination ---

            % Check if state determination failed
            if isnan(state) || state == -1
                warning('FluidEOS:StateDetFailed', 'State determination failed for T=%.2f K, rho=%.4e.', T, rho);
                Props = obj.createNaNProps(); 
                Props.state = -1; Props.T = T; Props.rho = rho;
                return;
            end
            
            % --- Assign Properties based on determined state --- 
            if state == 0 % Liquid
                u_l = u; s_l = s; h_l = h; cp_l = cp; cv_l = cv; c_l = c;
                rho_l_out = rho;
                % Get saturated vapor props for reference (ignore if error)
                if ~isnan(rho_v)
                   try
                        Helm_v_ref = obj.computeState(T, rho_v);
                        u_v = Helm_v_ref.u; s_v = Helm_v_ref.s; h_v = Helm_v_ref.h; cp_v = Helm_v_ref.cp; cv_v = Helm_v_ref.cv; c_v = Helm_v_ref.c;
                        rho_v_out = rho_v;
                   catch ME
                       warning('FluidEOS:SatVaporPropErrorLiquid', 'Error computing sat vapor props for state 0: %s', ME.message);
                       u_v = NaN; s_v = NaN; h_v = NaN; cp_v = NaN; cv_v = NaN; c_v = NaN; rho_v_out = NaN;
                   end
                else
                   u_v = NaN; s_v = NaN; h_v = NaN; cp_v = NaN; cv_v = NaN; c_v = NaN; rho_v_out = NaN;
                end

            elseif state == 2 % Vapor
                u_v = u; s_v = s; h_v = h; cp_v = cp; cv_v = cv; c_v = c;
                rho_v_out = rho;
                 % Get saturated liquid props for reference (ignore if error)
                if ~isnan(rho_l)
                    try
                        Helm_l_ref = obj.computeState(T, rho_l);
                        u_l = Helm_l_ref.u; s_l = Helm_l_ref.s; h_l = Helm_l_ref.h; cp_l = Helm_l_ref.cp; cv_l = Helm_l_ref.cv; c_l = Helm_l_ref.c;
                        rho_l_out = rho_l;
                    catch ME
                        warning('FluidEOS:SatLiquidPropErrorVapor', 'Error computing sat liquid props for state 2: %s', ME.message);
                        u_l = NaN; s_l = NaN; h_l = NaN; cp_l = NaN; cv_l = NaN; c_l = NaN; rho_l_out = NaN;
                    end
                else
                    u_l = NaN; s_l = NaN; h_l = NaN; cp_l = NaN; cv_l = NaN; c_l = NaN; rho_l_out = NaN;
                end
                
            else % Saturated (state == 1)
                if isnan(rho_l) || isnan(rho_v)
                     error('FluidEOS: Logic error - should not be state 1 with NaN sat densities');
                end
                try
                    Helm_l = obj.computeState(T, rho_l);
                    Helm_v = obj.computeState(T, rho_v);
                catch ME
                    warning('FluidEOS:SatPropError', 'Error computing sat props at T=%.2f K: %s', T, ME.message);
                    Props = obj.createNaNProps(); Props.state = -1; Props.T = T; Props.rho = rho;
                    return;
                end
                
                % Assign saturated props
                u_l = Helm_l.u; s_l = Helm_l.s; h_l = Helm_l.h; cp_l = Helm_l.cp; cv_l = Helm_l.cv; c_l = Helm_l.c;
                rho_l_out = rho_l;
                u_v = Helm_v.u; s_v = Helm_v.s; h_v = Helm_v.h; cp_v = Helm_v.cp; cv_v = Helm_v.cv; c_v = Helm_v.c;
                rho_v_out = rho_v;

                % Calculate mixture properties using quality X calculated earlier
                s = s_v*X + s_l*(1-X);
                u = u_v*X + u_l*(1-X);
                h = h_v*X + h_l*(1-X);
                cp = cp_v*X + cp_l*(1-X); % Approximation for cp
                cv = cv_v*X + cv_l*(1-X); % Approximation for cv

                % Calculate two-phase speed of sound
                if X == 0
                    c = c_l;
                elseif X == 1
                    c = c_v;
                else
                    term_v = X/rho_v;
                    term_l = (1-X)/rho_l;
                    alpha = term_v / (term_v + term_l); % Vapor volume fraction
                    % Check for division by zero/NaN if c_v or c_l is zero/NaN/invalid
                    c_term_v = alpha / (rho_v * c_v^2);
                    c_term_l = (1-alpha) / (rho_l * c_l^2);
                     if isfinite(c_term_v) && isfinite(c_term_l) && (c_term_v + c_term_l) > 0
                       c = sqrt(1 / (c_term_v + c_term_l));
                    else 
                       warning('FluidEOS:SoundSpeedNaN', 'Could not calculate two-phase sound speed at T=%.2f, X=%.4f.', T, X);
                       c = NaN; 
                    end
                end
                % For saturated state, use the pressure consistent with saturation temperature
                % P = Helm_v.P; % Or Helm_l.P, should be very close
                 try % Recalculate P using sat vapor density for consistency
                     P_sat = obj.computeState(T, rho_v).P;
                     P = P_sat; % Override P calculated from input rho with saturation pressure
                 catch 
                     warning('FluidEOS:SatPressureRecalcError', 'Could not recalculate Psat at T=%.2f', T);
                     % Keep original P calculated from Helm
                 end 
            end

            %% Output Assignment
            Props.state = state; % -1: 오류, 0: 액체, 1: 포화, 2: 기체
            Props.P = P;
            Props.T = T;
            Props.rho = rho;
            Props.u = u;
            Props.s = s;
            Props.h = h;
            Props.cp = cp;
            Props.cv = cv;
            Props.c = c;
            Props.rho_v = rho_v_out;
            Props.u_v = u_v;
            Props.s_v = s_v;
            Props.h_v = h_v;
            Props.cp_v = cp_v;
            Props.cv_v = cv_v;
            Props.c_v = c_v;
            Props.rho_l = rho_l_out;
            Props.u_l = u_l;
            Props.s_l = s_l;
            Props.h_l = h_l;
            Props.cp_l = cp_l;
            Props.cv_l = cv_l;
            Props.c_l = c_l;

            % --- Assign Final Quality based on State ---
            if state == 0
                Props.X = 0;
            elseif state == 2
                Props.X = 1;
            elseif state == 1
                Props.X = X; % Use the calculated (potentially unclamped) quality for state 1
            else % Error state or unhandled
                Props.X = NaN;
            end
            % --- End Final Quality Assignment ---
        end
        
        % Helper function to create a structure with NaN properties
        function Props = createNaNProps(obj)
            Props = struct();
            Props.state = NaN; Props.P = NaN; Props.T = NaN; Props.X = NaN;
            Props.rho = NaN; Props.u = NaN; Props.s = NaN; Props.h = NaN;
            Props.cp = NaN; Props.cv = NaN; Props.c = NaN;
            Props.rho_v = NaN; Props.u_v = NaN; Props.s_v = NaN; Props.h_v = NaN;
            Props.cp_v = NaN; Props.cv_v = NaN; Props.c_v = NaN;
            Props.rho_l = NaN; Props.u_l = NaN; Props.s_l = NaN; Props.h_l = NaN;
            Props.cp_l = NaN; Props.cv_l = NaN; Props.c_l = NaN;
        end
    end
end 