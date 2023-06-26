
local S = heatplace_api.translate

heatplace_api.fireplace = {}

local fireplace = heatplace_api.fireplace

function heatplace_api.heatplace_fireplace_finish(part_data)
  part_data.load = fireplace.load
  part_data.save = fireplace.save
  part_data.check = fireplace.check
  part_data.step = fireplace.step
  
  part_data.add_fuel = fireplace.add_fuel
  part_data.ignite_fuel = fireplace.ignite_fuel
  return part_data
end

function fireplace.get_atmosphere(pos)
  return {
    temp = heatplace_api.get_air_temp(pos),
    oxygen = 0.21,
    heat_capacity = 700,
  }
end

local fuel_keys = {
    "amount", -- 
    "temp", -- temp
    "volume_coef", -- volume = volume_coef*amount
    "surface_coef", -- surface = surface_coef*amount^(2/3)
    "heat_capacity", -- per amount and kelvin
    "solid_oxygen_need", -- per amount, optional
    "solid_burn_energy", -- energy created by burn (per amount)
    "burning_temp", -- solid burning temp
    "burning_coef", -- limitation of burning per surface
    "vapor_oxygen_need", -- per amount, optional
    "vapor_burn_energy", -- energy created by burn (per amount)
    "sublimation_temp", -- in kelvin
    "sublimation_heat", -- per amount
    "sublimation_coef", -- limitation per surface
    "surface_thermal_cond_coef", -- surface thermal condition from air to fuel
  }

function fireplace.load(part, pos, meta, data)
  local key = part.key.."_temp"
  data[key] = meta:get(key)
  if data[key] then
    data[key] = tonumber(data[key])
  else
    data[key] = heatplace_api.get_air_temp(pos)
  end
  for fuel=1,part.fuels do
    for _,fuel_key in pairs(fuel_keys) do
      key = part.key.."_fuel"..fuel.."_"..fuel_key
      data[key] = meta:get_float(key)
    end
  end
end

function fireplace.save(part, pos, meta, data)
  local key = part.key.."_temp"
  meta:set_float(key, data[key])
  for fuel=1,part.fuels do
    for _,fuel_key in pairs(fuel_keys) do
      key = part.key.."_fuel"..fuel.."_"..fuel_key
      meta:set_float(key, data[key])
    end
  end
end

function fireplace.check(part)
  if (type(part.fuels)~="number") then
    return false
  end
  if (type(part.fuel_volume_limit)~="number") then
    return false
  end
  if (type(part.air_flow_base)~="number") then
    return false
  end
  if (type(part.air_flow_coef)~="number") then
    return false
  end
  if (type(part.air_noflow)~="number") then
    return false
  end
  if (type(part.air_amount)~="number") then
    return false
  end
  return true
end

function fireplace.step(part, pos, meta, data, power, speed)
  local key_part_temp = part.key.."_temp"
  local sum_oxygen_need = 0
  
  local fuels_data = {}
  
  local air_amount = part.air_amount
  
  for fuel=1,part.fuels do
    local key_fuel = part.key.."_fuel"..fuel
    local amount = data[key_fuel.."_amount"]
    if (amount>0) then
      local fuel_data = {}
      fuels_data[fuel] = fuel_data
      
      local temp_key = key_fuel.."_temp"
      local temp = data[temp_key]
      local heat_capacity = data[key_fuel.."_heat_capacity"]/power
      local surface_coef = data[key_fuel.."_surface_coef"]
      local volume_coef = data[key_fuel.."_volume_coef"]
      
      local vapor_oxygen_need = data[key_fuel.."_vapor_oxygen_need"]
      local sublimation_temp = data[key_fuel.."_sublimation_temp"]
      
      local solid_oxygen_need = data[key_fuel.."_solid_oxygen_need"]
      local burning_temp = data[key_fuel.."_burning_temp"]
      -- burning
      local surface = (amount^(2/3))*surface_coef
      air_amount = air_amount - amount*volume_coef
      
      -- vaporing burning
      if (vapor_oxygen_need>0) and (temp>sublimation_temp) then
        local sublimation_heat = data[key_fuel.."_sublimation_heat"]/power
        local sublimation_coef = data[key_fuel.."_sublimation_coef"]
        local vapor_amount = math.min(math.min(amount, surface*sublimation_coef), ((temp-sublimation_temp)*heat_capacity/sublimation_heat))
        --local vapor_amount = math.min(amount, (((1/1+math.exp(-k*(temp-sublimation_temp)))+0.5)*))
        fuel_data["vapor_amount"] = vapor_amount
        sum_oxygen_need = sum_oxygen_need + vapor_amount*vapor_oxygen_need
        
        -- sublimation is prioritized before solid burning
        amount = amount - vapor_amount
        temp = (temp*heat_capacity - vapor_amount*sublimation_heat)/heat_capacity
        data[temp_key] = temp
        
        print("vapor_amount: "..dump(vapor_amount))
      end
      
      -- solid surface burning
      if (solid_oxygen_need>0) and (temp>burning_temp) then
        local burning_coef = data[key_fuel.."_burning_coef"]
        local burn_amount = math.min(amount, surface*burning_coef)
        fuel_data["burn_amount"] = burn_amount
        sum_oxygen_need = sum_oxygen_need + burn_amount*solid_oxygen_need
        
        print("burn_amount: "..dump(burn_amount))
      end      
    end
  end
  
  local atmosphere = fireplace.get_atmosphere(pos)
  local air_heat_capacity = atmosphere.heat_capacity/power
  local air_flow_limit = part.air_flow_base+part.air_flow_coef*(data[key_part_temp]-atmosphere.temp)
  local oxygen_aviable = air_flow_limit*atmosphere.oxygen
  local oxygen_part = math.min(1.0, (sum_oxygen_need/oxygen_aviable))
  
  local air_energy
  print("air_flow_limit: "..dump(air_flow_limit).." air_amount: "..air_amount.." part_temp: "..data[key_part_temp])
  if (air_flow_limit>=air_amount) then
    air_energy = air_flow_limit*air_heat_capacity*atmosphere.temp+air_flow_limit*air_heat_capacity*data[key_part_temp]
    air_amount = air_flow_limit
  else
    local flow_air_part = (air_flow_limit*oxygen_part)/air_amount
    local new_air_part = math.min(1.0, flow_air_part)
    air_energy = air_amount*new_air_part*air_heat_capacity*atmosphere.temp+air_amount*(1-new_air_part)*air_heat_capacity*data[key_part_temp]
    print("new_air_part: "..dump(new_air_part))
  end
  print("air_energy: "..dump(air_energy))
  
  for fuel=1,part.fuels do
    local key_fuel = part.key.."_fuel"..fuel
    local key_amount = key_fuel.."_amount"
    local amount = data[key_amount]
    if (amount>0) then
      local fuel_data = fuels_data[fuel]
      
      local temp = data[key_fuel.."_temp"]
      
      if fuel_data["vapor_amount"] then
        local vapor_burn_energy = data[key_fuel.."_vapor_burn_energy"]
        
        local vapor_amount = fuel_data["vapor_amount"]
        amount = amount - vapor_amount*speed
        air_energy = air_energy + temp*air_heat_capacity*vapor_amount + vapor_amount*vapor_burn_energy*oxygen_part
        air_amount = air_amount + vapor_amount
      end
      if fuel_data["burn_amount"] then
        local solid_burn_energy = data[key_fuel.."_solid_burn_energy"]
        
        local burn_amount = fuel_data["burn_amount"]*oxygen_part
        amount = amount - burn_amount*speed
        air_energy = air_energy + temp*air_heat_capacity*burn_amount + burn_amount*solid_burn_energy
        air_amount = air_amount + burn_amount
      end
      data[key_amount] = math.max(amount, 0)
    end
  end
  
  -- air temp
  local part_temp = air_energy/(air_heat_capacity*air_amount)
  print("air_energy: "..dump(air_energy).." air_heat_capacity: "..dump(air_heat_capacity).." part_temp: "..dump(data[key_part_temp]))
  
  for fuel=1,part.fuels do
    local key_fuel = part.key.."_fuel"..fuel
    local key_amount = key_fuel.."_amount"
    local amount = data[key_amount]
    if (amount>0) then
      local key_temp = key_fuel.."_temp"
      local fuel_data = fuels_data[fuel]
      
      local temp = data[key_temp]
      
      local heat_capacity = data[key_fuel.."_heat_capacity"]/power
      local surface_coef = data[key_fuel.."_surface_coef"]
      local surface_thermal_cond_coef = data[key_fuel.."_surface_thermal_cond_coef"]
      
      local heat_cond = (amount^(2/3))*surface_coef*surface_thermal_cond_coef*(part_temp-temp)
      
      air_energy = math.max(air_energy - heat_cond, 0)
      data[key_temp] = (temp*heat_capacity*amount+heat_cond)/(heat_capacity*amount)
      
      print("heat_cond: "..dump(heat_cond).." fuel_temp_change: "..dump(-heat_cond/(heat_capacity*amount)))
    end
  end
  
  -- store air energy in temp
  data[key_part_temp] = air_energy/(air_heat_capacity*air_amount)
  print("air_energy: "..dump(air_energy).." air_heat_capacity: "..dump(air_heat_capacity).." part_temp: "..dump(data[key_part_temp]))
end

-- custom callback
local function check_fuel_slot(part, data, slot, fuel_def)
  local key_fuel = part.key.."_fuel"..slot
  local key_amount = key_fuel.."_amount"
  local amount = data[key_amount]
  
  if (amount>0) then
    return false
  end
  
  if ((fuel_def.amount*fuel_def.volume_coef)>part.fuel_volume_limit) then
    return false
  end
  
  return true
end

function fireplace.add_fuel(part, pos, meta, data, fuel_item, fuel_slot, adder_name)
  local fuel_def = fuel_item:get_definition()
  
  if (not fuel_def) or (not fuel_def._heatplace_fuel) then
    if adder_name then
      minetest.chat_send_player(adder_name, S("This is not fuel supported by heatplace mod."))
    end
    return
  end
  
  if (not fuel_slot) then
    for fuel=1,part.fuels do
      if check_fuel_slot(part, data, fuel, fuel_def._heatplace_fuel) then
        fuel_slot = fuel
        break
      end
    end
  else
    if (not check_fuel_slot(part, data, fuel_slot, fuel_def._heatplace_fuel)) then
      fuel_slot = nil
    end
  end

  if fuel_slot then
    local key_fuel = part.key.."_fuel"..fuel_slot
    for _,key in pairs(fuel_keys) do
      local data_key = key_fuel.."_"..key
      data[data_key] = fuel_def._heatplace_fuel[key]
    end
    local data_key = key_fuel.."_temp"
    data[data_key] = heatplace_api.get_air_temp(pos)
    fuel_item:take_item()
  else
    if adder_name then
      minetest.chat_send_player(adder_name, S("Looks like there is no free space for add this kind of fuel into the fireplace."))
    end
  end
end

function fireplace.ignite_fuel(part, pos, meta, data, ignite_item, fuel_slot)
  local ignite_def = ignite_item:get_definition()
  
  if (not ignite_def) or (not ignite_def._heatplace_igniter) then
    if adder_name then
      minetest.chat_send_player(adder_name, S("This is not ignite supported by heatplace mod."))
    end
    return
  end
  
  local key_fuel = part.key.."_fuel"..fuel_slot
  local key_heat_capacity = key_fuel.."_heat_capacity"
  local key_temp = key_fuel.."_temp"
  
  local heat_capacity = data[key_heat_capacity]
  local temp = data[key_temp]
  
  temp = (heat_capacity*temp+ignite_def._heatplace_igniter.heat_per_use)/heat_capacity
  data[key_temp] = temp
end

