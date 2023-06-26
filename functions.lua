
function heatplace_api.get_air_temp(pos)
  return 273.15+10
end

function heatplace_api.heatplace_part_load_data(part, pos, meta, data)
  local key = part.key.."_temp"
  data[key] = meta:get_float(key)
end

function heatplace_api.heatplace_part_save_data(part, pos, meta, data)
  local key = part.key.."_temp"
  meta:get_float(key, data[key])
end

function heatplace_api.heatplace_part_air_check(part)
  return true
end
function heatplace_api.heatplace_part_air_step(part, pos, meta, data, power, speed)
  local key = part.key.."_temp"
  local keep_air = 0.5^speed
  data[key] = data[key]*keep_air+(1-keep_air)*heatplace_api.get_air_temp(pos)
end

function heatplace_api.heatplace_part_electric_heat_check(part)
  if (type(part.max_add_energy)~="number") then
    return false
  end
  if (type(part.heat_capacity)~="number") then
    return false
  end
  return true
end
function heatplace_api.heatplace_part_electric_heat_step(part, pos, meta, data, power, speed)
  local key = part.key.."_temp"
  
  local temp = (data[key]*part.heat_capacity+max_add_energy)/part.heat_capacity
  if part.max_temp and (temp>part.max_temp) then
    temp = math.max(part.max_temp, data[key])
  end
  data[key] = temp
end

function heatplace_api.heatplace_transport_heat_check(transport)
  if (type(transport.from)~="string") then
    return false
  end
  if (type(transport.to)~="string") then
    return false
  end
  if (type(transport.coef)~="number") then
    return false
  end
  return true
end
function heatplace_api.heatplace_transport_heat_step(transport, data, speed)
  local temp_from = transport.from.."_temp"
  local temp_to  = transport.to.."_temp"
  -- Q = A*(T1-T2)/d
  local Q = transport.coef * (data[temp_from]-data[temp_to]) * speed
  local avgT = (data[temp_from] + data[temp_to])/2
  
  if (data[temp_from]>=data[temp_to]) then
    data[temp_from] = (data[temp_from]*part_from.heat_capacity - Q)/part_from.heat_capacity
    data[temp_to] = (data[temp_to]*part_to.heat_capacity + Q)/part_to.heat_capacity
    
    if (data[temp_from]<data[temp_to]) then
      data[temp_from] = avgT
      data[temp_to] = avgT
    end
  else
    data[temp_from] = (data[temp_from]*part_from.heat_capacity - Q)/part_from.heat_capacity
    data[temp_to] = (data[temp_to]*part_to.heat_capacity + Q)/part_to.heat_capacity
    
    if (data[temp_from]>=data[temp_to]) then
      data[temp_from] = avgT
      data[temp_to] = avgT
    end
  end
  -- Q = A*(T2-T1)*t
  -- Q = A*((heat2-Q*dT)/Hcap2-(heat1+Q*dT)/Hcap1)*dt
end

