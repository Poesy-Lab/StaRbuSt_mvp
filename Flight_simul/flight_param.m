function out = flight_param(override)
%flight_param  비행 시뮬 기체/공력 파라미터 (persistent)
%   flight_param()          % 현재 파라미터 반환 (최초 호출 시 기본값 생성)
%   flight_param(override)  % 파라미터 주입 (헤드리스 러너용, 이후 호출부터 적용)
%   override에 없는 필드는 기본값을 유지한다.

persistent param

if isempty(param)
    param.C_A = 0.3;
    param.C_y= 0.15;
    param.C_z= 0.15;
    param.C_l = 0.15;
    param.C_m= 0.15;
    param.C_n= 0.15;
    % param.ISP = 200;
    % param.burn_time = 1000; % 실제 연소 시간은 TMS_Thrust에서 파생됨
    % param.mass_rate = 0.3; % 실제 질량 변화율은 effective_mass_rate 사용
   % param.propulsion_mass = param.mass_rate*param.burn_time;
    param.propulsion_mass = 1.4;
    param.total_mass = 15;
    param.diameter=0.110;
    param.ref_area = pi*param.diameter^2/4;
    param.total_moi = diag([44147306.548*10^(-6), 232608793.827*10^(-6), 213766034.312*10^(-6)]);
    param.end_moi = diag([42680897.630*10^(-6), 225827468.572*10^(-6), 207605643.605*10^(-6)]);
    % param.moi_rate = (param.total_moi-param.end_moi)/param.burn_time;
    param.rail_h=5;
end

if nargin > 0 && ~isempty(override)
    fn = fieldnames(override);
    for i = 1:numel(fn)
        param.(fn{i}) = override.(fn{i});
    end
    param.ref_area = pi*param.diameter^2/4; % 직경 변경 시 기준 면적 갱신
end

out = param;

end
