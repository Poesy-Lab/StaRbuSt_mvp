function out = N2O_SatTable(P)
%N2O_SatTable  N2O 포화선 물성 테이블 조회 (급기 라인/HEMc 핫루프 고속화)
%   첫 호출에서 CoolProp으로 포화선(0.92~71.5 bar, 420점)을 1회 구축한 뒤,
%   이후에는 py 브리지 호출 없이 보간(griddedInterpolant, pchip)으로 조회한다.
%   급기 라인 행진과 HEM 플럭스 계산은 전부 포화 돔 내부의 (P, 지렛대) 연산이므로
%   포화선 7종(T, h_l, h_v, s_l, s_v, rho_l, rho_v)만 있으면 충분하다.
%
%   입력:  P [Pa] (스칼라)
%   반환:  out.ok (범위 내 여부), out.T, hl, hv, sl, sv, rhol, rhov
%
%   주의: CoolProp(pyenv) 필요. 보간 오차는 포화선이 매끄러워 무시 가능
%         (임계점 직전 ~71.5 bar 초과는 범위 밖 처리).

persistent F Pmin Pmax
if isempty(F)
    fprintf('N2O_SatTable: 포화선 테이블 구축 중 (CoolProp, 최초 1회)... ');
    Pg = logspace(log10(0.92e5), log10(7.15e6), 420);
    n = numel(Pg);
    vals = zeros(7, n);
    outs = {'T', 'H', 'H', 'S', 'S', 'D', 'D'};
    qs   = [ 0,   0,   1,   0,   1,   0,   1 ];
    for i = 1:n
        for j = 1:7
            vals(j, i) = double(py.CoolProp.CoolProp.PropsSI(outs{j}, 'P', Pg(i), 'Q', qs(j), 'NitrousOxide'));
        end
    end
    lp = log(Pg);
    F.T    = griddedInterpolant(lp, vals(1, :), 'pchip');
    F.hl   = griddedInterpolant(lp, vals(2, :), 'pchip');
    F.hv   = griddedInterpolant(lp, vals(3, :), 'pchip');
    F.sl   = griddedInterpolant(lp, vals(4, :), 'pchip');
    F.sv   = griddedInterpolant(lp, vals(5, :), 'pchip');
    F.rhol = griddedInterpolant(lp, vals(6, :), 'pchip');
    F.rhov = griddedInterpolant(lp, vals(7, :), 'pchip');
    Pmin = Pg(1); Pmax = Pg(end);
    fprintf('완료 (%d점).\n', n);
end

if ~isfinite(P) || P < Pmin || P > Pmax
    out = struct('ok', false, 'T', NaN, 'hl', NaN, 'hv', NaN, ...
                 'sl', NaN, 'sv', NaN, 'rhol', NaN, 'rhov', NaN);
    return;
end
lp = log(P);
out.ok   = true;
out.T    = F.T(lp);
out.hl   = F.hl(lp);
out.hv   = F.hv(lp);
out.sl   = F.sl(lp);
out.sv   = F.sv(lp);
out.rhol = F.rhol(lp);
out.rhov = F.rhov(lp);
end
