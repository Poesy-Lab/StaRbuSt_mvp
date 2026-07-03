function [t_log, x_log] = int_RK4(dyn_func,time,init_x,event_func)

% Count the number of time points where integration results are returned.
N_time_pt = length(time);

% Get the dimension of the initial state(x), a column vector.
if size(init_x,1) == 1
    init_x = init_x'; % set the state vector a column
end
n = size(init_x,1);

% Prepare the return variables.
t_log = nan*zeros(N_time_pt,1);
x_log = nan*zeros(N_time_pt,n);

% Assign initial values.
t_log(1,1) = time(1);
x_log(1,:) = init_x';

for id_time = 1:N_time_pt-1

    % Read the current step values.
    t = t_log(id_time,1);
    x = x_log(id_time,:)'; % row -> column

    dt = (time(id_time+1)-time(id_time)); % time step
    
    % Integrate one step.
    k_1 = dyn_func(t,x);
    k_2 = dyn_func(t+dt/2,x+dt*k_1/2);
    k_3 = dyn_func(t+dt/2,x+dt*k_2/2);
    k_4 = dyn_func(t+dt,x+dt*k_3);
    dx = (k_1+2*k_2+2*k_3+k_4)/6;
    x = x + dt*dx; % a column vector

    % Store the next step values.
    t_log(id_time+1,1) = time(id_time+1);
    x_log(id_time+1,:) = x'; % column -> row
%     x_log(id,3)

    if nargin >= 4 && event_func(time(id_time+1),x)
        break;
    end
    
end