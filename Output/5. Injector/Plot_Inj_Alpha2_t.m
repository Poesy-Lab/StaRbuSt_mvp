function Plot_Inj_Alpha2_t(ax, y)
%Plot_Inj_Alpha2_t Plots the FML downstream void fraction and choking flag vs. time.
%   왼쪽 축: 하류 보이드율 alpha2 (FML 가중치, 0~1)
%   오른쪽 축: 초킹 여부 choked (0/1)
%   NHNE/CdA 모델 실행에서는 값이 없어(전부 NaN) Plot_Inj_Results에서
%   이 탭 자체가 생략된다.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.alpha2;
%          y.inj.choked is optional).

yyaxis(ax, 'left');
plot(ax, y.time, y.inj.alpha2, 'Color', [0.4940 0.1840 0.5560], 'LineStyle', '-', 'LineWidth', 1.8);
ylabel(ax, 'Void Fraction \alpha_2 (-)');
ylim(ax, [-0.05, 1.05]);

if isfield(y.inj, 'choked') && any(~isnan(y.inj.choked))
    yyaxis(ax, 'right');
    stairs(ax, y.time, double(y.inj.choked), 'Color', [0.8500 0.3250 0.0980], 'LineStyle', '--', 'LineWidth', 1.2);
    ylabel(ax, 'Choked (0/1)');
    ylim(ax, [-0.05, 1.05]);
end

grid(ax, 'on');
xlabel(ax, 'Time (s)');
title(ax, 'FML Void Fraction (\alpha_2) & Choking Flag vs Time');

end
