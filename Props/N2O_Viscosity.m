function [mu_l, mu_v] = N2O_Viscosity(T)
%N2O_Viscosity  N2O 포화 액체/증기 점도 [Pa s] - ESDU 91022 상관식
%   인하우스 HelmholtzEOS와 CoolProp 모두 N2O 점도 모델이 없어 별도 함수로 제공.
%   급기 라인(Feed_Line)의 2상 마찰 계산(Dukler 점도)에 사용.
%   유효 범위: 삼중점(182.3 K) ~ 임계점 부근.
Tc = 309.57; % K

% 포화 액체
theta = (Tc - 5.24) ./ (T - 5.24);
mu_l = 0.0293423e-3 .* exp(1.6089 .* (theta - 1));

% 포화 증기
b = Tc ./ T - 1;
mu_v = 1e-6 .* exp(3.3281 - 1.18237 .* b.^(1/3) - 0.055155 .* b.^(4/3));
end
