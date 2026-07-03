function Plot_Inj_Mdot_Combined_t(ax, y)
%Plot_Inj_Mdot_Combined_t Plots total and model component mass flow rates.
%   총 유량 y.inj.mdot과 함께, 사용한 인젝터 모델의 성분 유량을 표시한다.
%   - NHNE 모델: mdot_inc, mdot_HEM
%   - FML 모델:  mdot_SPC, mdot_HEM
%   기록이 전부 NaN인 성분(해당 모델 미사용)은 자동으로 생략된다.
%
%   Inputs:
%       ax: Axes handle to plot on.
%       y: Simulation results structure (must contain y.time, y.inj.mdot;
%          component fields are optional and plotted only when data exists).

% 해당 필드에 유효한(NaN이 아닌) 기록이 하나라도 있는지 확인
has_data = @(f) isfield(y.inj, f) && any(~isnan(y.inj.(f)));

plot(ax, y.time, y.inj.mdot, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Total (mdot)');
hold(ax, 'on');
if has_data('mdot_inc')
    plot(ax, y.time, y.inj.mdot_inc, 'Color', [0 0.4470 0.7410], 'LineStyle', '--', 'LineWidth', 1.5, 'DisplayName', 'NHNE: mdot_{inc}');
end
if has_data('mdot_SPC')
    plot(ax, y.time, y.inj.mdot_SPC, 'Color', [0.4660 0.6740 0.1880], 'LineStyle', '--', 'LineWidth', 1.5, 'DisplayName', 'FML: mdot_{SPC}');
end
if has_data('mdot_HEM')
    plot(ax, y.time, y.inj.mdot_HEM, 'Color', [0.6350 0.0780 0.1840], 'LineStyle', ':', 'LineWidth', 1.5, 'DisplayName', 'mdot_{HEM}');
end
hold(ax, 'off');

grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, 'Mass Flow Rate (kg/s)');
title(ax, 'Injector Mass Flow Rates (Total & Model Components) vs Time');
legend(ax, 'show', 'Location', 'best');

end
