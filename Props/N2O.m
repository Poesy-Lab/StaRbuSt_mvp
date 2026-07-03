classdef N2O < FluidEOS
	properties (Constant)
		% 임계점 상수
		Tc = 309.52; % K
		rhoc = 452.011456; % kg/m^3
		
		% 기체 상수 계산용
		Ru = 8.31446261815324; % J/(mol·K)
		M = 44.0128e-3; % kg/mol
		R = N2O.Ru / N2O.M; % J/(kg·K)
		
		% 이상 기체 헬름홀츠 에너지 계수
		a1 = -4.4262736272;
		a2 = 4.3120475243;
		c0 = 3.5;
		c1 = 0;
		c2= 0;
		
		% 이상 기체 Cp 모델의 Einstein 계수
		v = [ ...
			    2.1769,    ... % v1
			    1.6145,    ... % v2
			    0.48393,   ... % v3
			];
		
		u = [ ...
			    879,      ... % u1
			    2372,     ... % u2
				5447,     ... % u3
			];
		
		% 무극성은 0, 극성은 1
		fluid_state = 1;             % Polar
		
		% 잔여 헬름홀츠 에너지 계수
		n = [ ...
				0.88045,    ... % n1
				-2.4235,    ... % n2
				0.38237,    ... % n3
			    0.068917,   ... % n4
			    0.00020367, ... % n5
			    0.13122,    ... % n6
			    0.46032,    ... % n7
				-0.0036985, ... % n8
				-0.23263,   ... % n9
				-0.00042859,... % n10
				-0.042810,  ... % n11
				-0.023038      % n12
			];
            
        % CEA Card String for N2O as oxidizer
        CEACard = ['oxid N2O N 2.0 O 1.0 wt%=100.0', newline, ...
			       'h,cal = 19467.0 t(k) = 298.15']; % h: cal/mol
    end

    methods
        function [rhoL, rhoV] = satDensity(~, Tq)
            % satDensity: 온도 Tq에 대한 포화 액체/증기 밀도 보간 (Reverted to original interp1 version)
            persistent Tl rhol Tv rhov % Restore persistent variables for Excel data
            if isempty(Tl)
                % Restore reading from Excel file
                L = readmatrix("N2O.xlsx","Sheet","N2O_saturation_liquid");
                V = readmatrix("N2O.xlsx","Sheet","N2O_saturation_vapor");
                Tl   = L(:,1);    rhol = L(:,3);
                Tv   = V(:,1);    rhov = V(:,3);
            end
            % Restore interp1 calls (without caching)
            rhoL = interp1(Tl,   rhol, Tq, 'spline');
            rhoV = interp1(Tv,   rhov, Tq, 'spline');
        end
    end
end