
heatplace_api.transport = {}

local transport = heatplace_api.transport

function heatplace_api.heatplace_transport_finish(transport_data)
  transport_data.check = transport.check
  transport_data.step = transport.step
  return transport_data
end

function transport.check(transport)
  if (type(transport.thermal_cond)~="number") then
    return false
  end
  if (type(transport.temp1_key)~="string") then
    return false
  end
  if (type(transport.temp2_key)~="string") then
    return false
  end
  if (type(transport.heat1_cap)~="number") then
    return false
  end
  if (type(transport.heat2_cap)~="number") then
    return false
  end
  return true
end

function transport.step(transport, pos, meta, data, speed)
  local heat1_cap = transport.heat1_cap
  local heat2_cap = transport.heat2_cap
  
  local temp1 = data[transport.temp1_key]
  local temp2 = data[transport.temp2_key]
  local temp_diff = temp2 - temp1
  local cond_move = temp_diff*transport.thermal_cond*speed
  -- temp1+cond_limit/heat1_cap = temp2-cond_limit/heat2_cap
  local cond_limit = (heat1_cap*heat2_cap*temp_diff)/(heat2_cap+heat1_cap)
  
  if (math.abs(cond_move)>math.abs(cond_limit)) then
    cond_move = cond_limit
  end
  
  data[transport.temp1_key] = temp1 + cond_move/heat1_cap
  data[transport.temp2_key] = temp2 - cond_move/heat2_cap
end

