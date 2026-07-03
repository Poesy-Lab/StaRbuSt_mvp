function [x] = Input(u, unit)
    x = struct();

    x_part = Init_Amb(u, unit);
    if isfield(x_part, 'amb')
        x.amb = x_part.amb;
    end

    x_part = Init_Tank(u, unit);
    fluid_assigned = false;
    if isfield(x_part, 'tank')
        x.tank = x_part.tank;
        if isfield(x.tank, 'fluid')
            x.fluid = x.tank.fluid;
            fluid_assigned = true;
        end
    end
    if ~fluid_assigned
        warning('Input:MissingFluid', 'Fluid object not found in Init_Tank output (expected at x_part.tank.fluid). Calculations requiring fluid properties will fail.');
        x.fluid = []; % Assign empty if missing to prevent downstream errors trying to access it
    end

    x_part = Init_Vent(u, unit);
    if isfield(x_part, 'vent')
        x.vent = x_part.vent;
    end

    x_part = Init_Inj(u, unit);
    if isfield(x_part, 'inj')
        x.inj = x_part.inj;
    end

    x_part = Init_Subinj(u, unit);
    if isfield(x_part, 'subinj')
        x.subinj = x_part.subinj;
    end

    x_part = Init_Fuel(u, unit);
    if isfield(x_part, 'fuel')
        x.fuel = x_part.fuel;
    end

    x_part = Init_Comb(u, unit);
    if isfield(x_part, 'comb')
        x.comb = x_part.comb;
    end

    x_part = Init_Nozzle(u, unit);
    if isfield(x_part, 'nozzle')
        x.nozzle = x_part.nozzle;
    end

    x_part = Init_Time(u, unit);
    if isfield(x_part, 'time')
        x.time = x_part.time;
    end

    x_part = Init_Simulset(u, unit);
    if isfield(x_part, 'test')
        x.test = x_part.test;
    end

    %% Final Initializations
    % Set initial combustion pressure to ambient pressure
    if isfield(x, 'comb') && isfield(x, 'amb') && isfield(x.amb, 'P')
        if ~isfield(x.comb, 'P') || isnan(x.comb.P) % Set only if not already set by Init_Comb
             x.comb.P = x.amb.P; 
        end
    else
        warning('Input:CannotSetInitialPc', 'Could not set initial Pc to ambient pressure. Required fields missing.');
    end

    % Create CEA Object using propellant names and cards
    x.cea = []; % Initialize as empty
    % Check if all required info exists (names in u, cards/objects in x)
    if isfield(u, 'tank') && isfield(u.tank, 'fluid') && ...
       isfield(u, 'fuel') && isfield(u.fuel, 'card') && ...
       isfield(x, 'fluid') && ~isempty(x.fluid) && isprop(x.fluid, 'CEACard') && ...
       isfield(x, 'fuel') && isfield(x.fuel, 'card')
        
        ox_name_str = string(u.tank.fluid);  % Oxidizer name from user input (e.g., "N2O")
        fuel_name_str = string(u.fuel.card); % Fuel name from user input (e.g., "HDPE")
        ox_card = x.fluid.CEACard;           % Oxidizer card from fluid object
        fuel_card = x.fuel.card;             % Fuel card from fuel init
        
        try
            % Register propellants using the proven py.rocketcea.cea_obj path
            py.rocketcea.cea_obj.add_new_oxidizer(ox_name_str, ox_card);
            py.rocketcea.cea_obj.add_new_fuel(fuel_name_str, fuel_card);
             
            % Create CEA_Obj instance using the registered names
            % Pass fuelName and oxName as strings
            x.cea = py.rocketcea.cea_obj.CEA_Obj(pyargs('fuelName', char(fuel_name_str), 'oxName', char(ox_name_str))); 
             
        catch ME
            warning('Input:CEAError', 'Failed during CEA registration or object creation (using py.rocketcea.cea_obj): %s', ME.message);
            fprintf('Error Details: Identifier=%s, Line=%d\n', ME.identifier, ME.stack(1).line);
             if ~isempty(ME.cause)
                 fprintf('Cause: %s\n', ME.cause{1}.message);
            end
            x.cea = []; % Ensure cea is empty on failure
        end
    else
        warning('Input:MissingCEAReqs', 'Could not create CEA object. Missing u/x fields for fluid/fuel names/cards.');
    end

end 