function y = StoreState(y, x, k, fields_to_log)
%% Store State
% Stores the current state from x into the history structure y at index k.
% Input: y - History structure.
%        x - Current state structure.
%        k - Current time step index.
%        fields_to_log - Cell array defining logged fields.
% Output: y - Updated history structure.

y.time(k) = x.time.current; % Store current time first

% Loop through component-field pairs defined outside the function
i = 1;
while i <= length(fields_to_log)
    component_name = fields_to_log{i};
    field_names = fields_to_log{i+1};
    if isfield(x, component_name) % Check if component exists in x
        for j = 1:length(field_names)
             field_name = field_names{j};
             if isfield(x.(component_name), field_name) % Check if field exists
                % Check if the field in y is pre-allocated and k is within bounds
                if isfield(y.(component_name), field_name) && ...
                   length(y.(component_name).(field_name)) >= k
                    y.(component_name).(field_name)(k) = x.(component_name).(field_name);
                else
                    warning('StoreState:FieldMismatch', 'Field %s.%s not pre-allocated or index k=%d out of bounds.', component_name, field_name, k);
                end
             % else
                % Optional: Handle cases where a field might be missing in x
                % y.(component_name).(field_name)(k) = NaN; % Or some default
             end
        end
    % else
        % Optional: Handle cases where a component might be missing in x
        % warning('StoreState:ComponentMissing', 'Component %s not found in x at k=%d.', component_name, k);
    end
    i = i + 2;
end

end 