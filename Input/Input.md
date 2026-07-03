---
tags:
  - 입력
  - 초기화
  - 메인
---
# 소개
- `Input.m` 함수는 시뮬레이션에 필요한 모든 초기 상태 및 설정값을 통합하여 단일 구조체 `x`로 만드는 역할을 합니다.
- 사용자가 `Test_StaRbuSt.m`과 같은 메인 스크립트에서 정의한 입력 구조체 `u`와 단위 구조체 `unit`을 인수로 받습니다.
- 각 컴포넌트별 초기화 함수 (`Init_Amb`, `Init_Tank`, `Init_Vent` 등)를 순차적으로 호출하고, 각 함수가 반환하는 구조체의 필드들을 최종 `x` 구조체로 병합합니다.

# Input

| 인수 | 설명                                                                 |
| ---- | -------------------------------------------------------------------- |
| `u`  | 사용자가 정의한 모든 입력 파라미터를 포함하는 구조체 (예: `u.tank.V`, `u.vent.model`). | 
| `unit`| `u` 구조체의 각 파라미터에 대한 단위를 지정하는 구조체 (예: `unit.tank.V = "L"`). | 

# System
1.  최종 출력 구조체 `x`를 빈 구조체로 초기화합니다.
2.  각 컴포넌트 (Ambient, Tank, Vent, Injector, Fuel, Combustor, Nozzle, Time, Simulation Settings)에 해당하는 `Init_*` 함수를 `u`와 `unit`을 인수로 전달하여 호출합니다.
3.  각 `Init_*` 함수는 해당 컴포넌트의 초기 상태를 담은 임시 구조체 `x_part`를 반환합니다.
4.  `isfield` 함수를 사용하여 `x_part`에 해당 컴포넌트 이름 (예: 'tank', 'vent')의 필드가 있는지 확인합니다.
5.  필드가 존재하면, 해당 필드의 내용 (예: `x_part.tank`)을 최종 `x` 구조체의 동일한 이름의 필드 (예: `x.tank`)에 할당합니다.
6.  **유체 객체 처리:**
    - `Init_Tank` 함수 호출 후, 반환된 `x_part` 구조체에 `tank` 필드가 있는지 먼저 확인합니다.
    - `x_part.tank` 필드가 존재하면, 이 `tank` 하위 구조체 **내부**에 `fluid` 필드가 있는지 다시 확인합니다 (`isfield(x.tank, 'fluid')`).
    - `x.tank.fluid` 필드가 존재하면 (즉, `Init_Tank`가 예상대로 유체 객체를 생성하여 `tank` 구조체 내부에 반환하면), 이 객체를 최종 `x` 구조체의 최상위 필드 `x.fluid`에 할당합니다.
    - `x.fluid`는 시뮬레이션 중 유체 물성 계산 (`Props` 라이브러리 등 사용)에 필요합니다.
    - 만약 `x.tank.fluid`가 존재하지 않으면 경고 메시지가 표시됩니다.
7.  모든 `Init_*` 함수 호출 및 병합이 완료된 후, **초기 연소실 압력(`x.comb.P`)을 대기압(`x.amb.P`)으로 설정합니다.** (`Init_Comb`에서 이미 설정하지 않은 경우).
8.  **CEA 객체 생성:**
    - 필요한 정보 (사용자 입력 `u`의 산화제/연료 이름, `x` 구조체의 유체 객체/연료 카드)가 모두 존재하는지 확인합니다.
    - 산화제 이름 (`u.tank.fluid`)과 산화제 카드 (`x.fluid.CEACard`), 연료 이름 (`u.fuel.card`)과 연료 카드 (`x.fuel.card`)를 가져옵니다.
    - **(디버깅) CEA 함수에 전달될 이름 및 카드 문자열 변수들의 내용을 출력하여 확인합니다.**
    - `py.rocketcea.cea_obj.add_new_oxidizer` 및 `add_new_fuel` 함수를 호출하여 이름과 카드를 CEA 라이브러리에 등록합니다.
    - `py.rocketcea.cea_obj.CEA_Obj` 생성자를 호출할 때, `fuelName`과 `oxName` 인자에 등록된 **이름** (문자 배열)을 전달하여 CEA 객체를 생성하고 `x.cea`에 저장합니다.
    - 필요한 정보가 없거나 등록/객체 생성 중 오류가 발생하면 경고 메시지가 표시되고 `x.cea`는 비어있게 됩니다.
9.  모든 초기 상태와 설정이 포함된 최종 `x` 구조체를 반환합니다.

# Output

| 반환값 | 설명                                                                                                                               |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `x`    | 모든 컴포넌트의 초기 상태, 설정값, 유체 객체 (`x.fluid`), **그리고 CEA 객체 (`x.cea`)**를 포함하는 최종 통합 구조체. 이 구조체는 `System.m` 함수의 입력으로 사용됩니다. | 

# 전체 코드
```MATLAB
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