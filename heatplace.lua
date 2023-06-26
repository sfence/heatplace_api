
-- heatplace api

heatplace_api.heatplace = {};
local heatplace = heatplace_api.heatplace;

function heatplace:new(def)
  def = def or {};
  for key, value in pairs(self) do
    if (type(value)~="function") and (def[key]==nil) then
      if (type(value)=="table") then
        def[key] = table.copy(value);
      else
        def[key] = value;
      end
    end
  end
  setmetatable(def, {__index = self});
  return def;
end

heatplace.parts = {}
heatplace.transports = {}
heatplace.meta_keys = {}

local check_callbacks = {"load", "save"}

function heatplace:add_heatplace_part(part_key, part_def)
  -- some checks
  if self.parts[part_key] then
    minetest.log("error", "[heatplace_api]: Part with key \""..part_key.."\" is already defined.")
    return
  end
  for _, callback in pairs(check_callbacks) do
    if (not part_def[callback]) then
      minetest.log("error", "[heatplace_api]: Part with key \""..part_key.."\" does not have "..callback.." callback.")
      return
    end
  end
  if part_def.check then
    if (not part_def.check(part_def)) then
      minetest.log("error", "[heatplace_api]: Part with key \""..part_key.."\" check callback failed.")
      return
    end
    part_def.check = nil
  end
  -- add it
  part_def.key = part_key
  self.parts[part_key] = part_def
end

function heatplace:get_heatplace_part(part_key)
  return self.parts[part_key]
end

function heatplace:add_heatplace_transport(transport_key, transport_def)
  if (not transport_def.step) then
    minetest.log("error", "[heatplace_api]: Transport with key \""..transport_key.."\" without step callback.")
    return
  end
  if transport_def.check then
    if (not transport_def.check(transport_def)) then
      minetest.log("error", "[heatplace_api]: Transport with key \""..transport_key.."\" check callback failed.")
      return
    end
    transport_def.check = nil
  end
  self.transports[transport_key] = transport_def
end

function heatplace:get_heatplace_transport(transport_key)
  return self.transports[transport_key]
end

function heatplace:load_data(pos, meta)
  data = {}
  for _, part in pairs(self.parts) do
    part.load(part, pos, meta, data)
  end
  return data
end

function heatplace:save_data(pos, meta, data)
  for _, part in pairs(self.parts) do
    part.save(part, pos, meta, data)
  end
end

function heatplace:step_heatplace(pos, meta, power, speed, steps)
  if (not power) then
    power = 1
  end
  if (not speed) then
    speed = heatplace_api.settings.speed
  end
  if (not steps) then
    steps = heatplace_api.settings.steps
  end
  
  if (not meta) then
    meta = minetest.get_meta(pos)
  end
  
  -- get data from meta
  local data = self:load_data(pos, meta)
  
  -- do heatplace
  for step = 1,steps do
    -- process heat sources
    for _, part in pairs(self.parts) do
      if part.step then
        part.step(part, pos, meta, data, power, speed)
      end
    end
    -- process heat transport
    for _, transport in pairs(self.transports) do
      transport.step(transport, pos, meta, data, speed)
    end
  end
  
  -- store data to meta
  self:save_data(pos, meta, data)
end

