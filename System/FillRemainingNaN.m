function y = FillRemainingNaN(y, start_index, end_index, fields_to_log)
%% Fill Remaining NaN
% Fills the history structure y with NaNs from start_index to end_index.
% Used when simulation stops prematurely.
% Input: y - History structure.
%        start_index - Index from which to start filling NaNs.
%        end_index - Index up to which to fill NaNs.
%        fields_to_log - Cell array defining logged fields.
% Output: y - Updated history structure with NaNs.

if start_index > end_index || start_index > length(y.time)
    return;
end
% Ensure end_index does not exceed allocated size
end_index = min(end_index, length(y.time));

y.time(start_index:end_index) = NaN;
i = 1;
while i <= length(fields_to_log)
    component_name = fields_to_log{i};
    field_names = fields_to_log{i+1};
    if isfield(y, component_name)
        for j = 1:length(field_names)
             field_name = field_names{j};
             if isfield(y.(component_name), field_name)
                % Check if field is not empty before accessing indices
                if ~isempty(y.(component_name).(field_name))
                    y.(component_name).(field_name)(start_index:end_index) = NaN;
                end
             end
        end
    end
    i = i + 2;
end

end 