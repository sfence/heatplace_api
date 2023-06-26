
heatplace_api.body = {}

local body = heatplace_api.body

function heatplace_api.heatplace_body_finish(part_data)
  part_data.load = body.load
  part_data.save = body.save
  part_data.check = body.check
  return part_data
end

function body.load(part, pos, meta, data)
  local key = part.key.."_temp"
  data[key] = meta:get(key)
  if data[key] then
    data[key] = tonumber(data[key])
  else
    data[key] = heatplace_api.get_air_temp(pos)
  end
end

function body.save(part, pos, meta, data)
  local key = part.key.."_temp"
  meta:set_float(key, data[key])
end

function body.check(part)
  if (type(part.heat_capacity)~="number") then
    return false
  end
  return true
end

