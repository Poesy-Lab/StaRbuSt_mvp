function x = SetUnusedOutputs(x, phase)
%% Set Unused Outputs
% Sets unused outputs in the state structure x to 0 based on the current
% simulation phase or test mode.
% Input: x - Current state structure.
%        phase - String indicating the current phase ('PreFeed', 'LiqFeed', etc.)
% Output: x - Updated state structure with unused fields set to 0.

fields_to_set = struct();
switch phase
    case {'PreFeed', 'PostRun'} % Apply same settings for PreFeed and PostRun/Stop
        % Injector: keep T (ambient), P (ambient if set); 0 others
        fields_to_set.inj = {'mdot', 'rho', 'state', 'X', 'u', 'u_v', 'u_l', 's', 's_v', 's_l', 'h', 'h_v', 'h_l', 'cp', 'cp_v', 'cp_l', 'cv', 'cv_v', 'cv_l', 'rho_v', 'rho_l', 'kappa', 'mdot_inc', 'mdot_HEM', 'ratio_Pcr', 'ratio_P'};
        % Fuel: 0 flow-related, keep geometry
        fields_to_set.fuel = {'Gox', 'rdot', 'mdot', 'dR_m'};
        % Comb: keep T (ambient), P (ambient); 0 others
        fields_to_set.comb = {'mdot', 'OF', 'cstar', 'eta'};
        % Nozzle: 0 all
        fields_to_set.nozzle = {'Cf', 'F', 'Isp_sl'};
    case 'LiqFeed' % LiqFeed calculates most things, maybe only vent ratios are 0 if vent disabled?
         if x.vent.mode == 0
             fields_to_set.vent = {'ratio_Pcr', 'ratio_P'};
         end
         % Add other LiqFeed specific settings if needed
    case 'VapFeed'
         % Similar to LiqFeed, 0 vent ratios if vent is off
         if x.vent.mode == 0
             fields_to_set.vent = {'ratio_Pcr', 'ratio_P'};
         end
         % NHNE components are explicitly zeroed in VapFeed loop
         fields_to_set.inj = {'mdot_inc', 'mdot_HEM'}; % Set to zero
    case 'SprayTest' % Set fuel, comb (except P, T), and nozzle outputs to 0
        fields_to_set.fuel = {'Gox', 'rdot', 'mdot', 'dR_m'};
        fields_to_set.comb = {'mdot', 'OF', 'cstar', 'eta'}; % Keep P, T
        fields_to_set.nozzle = {'Cf', 'F', 'Isp_sl'};
        % Injector and Vent outputs are calculated normally based on ambient backpressure
end

components = fieldnames(fields_to_set);
for i = 1:length(components)
    comp = components{i};
    fields = fields_to_set.(comp);
    if ~isfield(x, comp)
         x.(comp) = struct(); % Create component struct if it doesn't exist
    end
    for j = 1:length(fields)
        field = fields{j};
        % Set all specified unused fields to 0
        x.(comp).(field) = 0;
    end
end

end 