function [out] = Feed_Line(x, mdot)
%Feed_Line  급기 라인 (P,h) 균질류 행진 모델 - 액상 유출 전용
%   경로: 탱크 출구(입구손실) -> 플렉시블(주름 마찰 배수, 벤드) -> 파이프1
%         -> 볼밸브(2상 무회복 K) -> 파이프2(인젝터 전방)
%   - 균질류 + Dukler 2상 점도 + Nikuradse 마찰: Tada et al. 2024가 자가가압 N2O
%     라인(기포류)에서 MAE 12~15%로 검증한 조합
%   - 가속 압손(플래싱으로 비체적 증가) 포함, 라인 단열 -> 엔탈피 보존
%   - 2026 수류시험 단독 검증: P_inj 교차 RMSE ~2.5 bar
%   요구 사항: CoolProp 물성 모델 (GetPropsPH 직접 플래시)
%
%   입력:  x (시뮬 상태), mdot [kg/s] (가정 유량 - 결합 루프에서 반복 호출됨)
%   반환:  out.ok      계산 성공 여부 (false: 해당 유량이 라인을 통과 불가)
%          out.P_out   라인 출구(인젝터 전방) 압력 [Pa]
%          out.h_out   라인 출구 비엔탈피 [J/kg] (= 탱크 액상 h, 보존)
%          out.x_out   라인 출구 건도
%          out.rho_out 라인 출구 혼합 밀도 [kg/m^3]
%          out.dP_line 라인 총 압력손실 [Pa]

fluid = x.fluid;
fd = x.feed;
h1 = x.tank.h_l; % 액상 유출 (단열 라인 -> h 보존)
P0 = x.tank.P;

out = struct('ok', false, 'P_out', NaN, 'h_out', h1, 'x_out', NaN, ...
             'rho_out', NaN, 'dP_line', NaN);

if ~ismethod(fluid, 'GetPropsPH')
    error('Feed_Line:PropModel', ...
        '급기 라인 모델은 CoolProp 물성 모델(u.tank.prop_model = "CoolProp")에서만 지원됩니다.');
end
if ~isfinite(mdot) || mdot <= 0
    return;
end

G_pipe = mdot / fd.pipe.A;
G_flex = mdot / fd.flex.A;

P = k_element(fluid, P0, h1, G_pipe, fd.K_ent);                                  % 탱크 출구 입구손실
if isfinite(P), P = pipe_march(fluid, P, h1, G_flex, fd.flex.D, fd.flex.L, fd.flex.fmult); end
if isfinite(P), P = k_element(fluid, P, h1, G_flex, fd.flex.K_bend); end         % ㄴ자 벤드
if isfinite(P), P = pipe_march(fluid, P, h1, G_pipe, fd.pipe.D, fd.pipe.L1, 1.0); end
if isfinite(P), P = k_element(fluid, P, h1, G_pipe, fd.valve.K); end             % 볼밸브 (2상 무회복)
if isfinite(P), P = pipe_march(fluid, P, h1, G_pipe, fd.pipe.D, fd.pipe.L2, 1.0); end

if isfinite(P)
    Props = fluid.GetPropsPH(P, h1);
    if Props.state ~= -1 && isfinite(Props.rho)
        out.ok = true;
        out.P_out = P;
        out.x_out = Props.X;
        out.rho_out = Props.rho;
        out.dP_line = P0 - P;
    end
end

end

function [rho, mu] = tp_props(fluid, P, h)
%tp_props (P,h) 상태의 균질 밀도와 Dukler 2상 점도
Props = fluid.GetPropsPH(P, h);
if Props.state == -1 || ~isfinite(Props.rho)
    rho = NaN; mu = NaN;
    return;
end
rho = Props.rho;
[mul, muv] = N2O_Viscosity(Props.T);
if Props.state == 1 && Props.rho_v > 0 && Props.rho_l > 0
    X = Props.X;
    alpha = (X / Props.rho_v) / (X / Props.rho_v + (1 - X) / Props.rho_l); % 균질 보이드율
    mu = alpha * muv + (1 - alpha) * mul; % Dukler: mu = a*mu_G + (1-a)*mu_L
elseif Props.state == 2
    mu = muv;
else
    mu = mul;
end
end

function f = fric_f(Re)
f = 0.0032 + 0.221 * Re^(-0.237); % Nikuradse (Tada 2024 사용식, Re > 1e5)
end

function P = pipe_march(fluid, P, h, G, D, L, fmult)
%pipe_march 직관 구간 행진 (마찰 + 가속 압손). 통과 불가 시 NaN.
P_FLOOR = 1.15e5;
n = max(1, round(L / 0.05)); % 0.05 m 간격 이산화
dL = L / n;
for i = 1:n
    [rho, mu] = tp_props(fluid, P, h);
    if ~isfinite(rho), P = NaN; return; end
    dPf = fmult * fric_f(G * D / mu) * (dL / D) * G^2 / (2 * rho);
    P_new = P - dPf;
    if P_new < P_FLOOR, P = NaN; return; end
    [rho2, ~] = tp_props(fluid, P_new, h);
    if ~isfinite(rho2), P = NaN; return; end
    P = P - dPf - G^2 * (1/rho2 - 1/rho); % 가속항 (균질 운동량식, 1회 보정)
    if P < P_FLOOR, P = NaN; return; end
end
end

function P = k_element(fluid, P, h, G, K)
%k_element 집중 손실 요소 (K계수) + 가속 보정. 통과 불가 시 NaN.
P_FLOOR = 1.15e5;
if K <= 0
    return;
end
[rho, ~] = tp_props(fluid, P, h);
if ~isfinite(rho), P = NaN; return; end
P_new = P - K * G^2 / (2 * rho);
if P_new < P_FLOOR, P = NaN; return; end
[rho2, ~] = tp_props(fluid, P_new, h);
if ~isfinite(rho2), P = NaN; return; end
P = P - K * G^2 / (2 * rho) - G^2 * (1/rho2 - 1/rho);
if P < P_FLOOR, P = NaN; end
end
