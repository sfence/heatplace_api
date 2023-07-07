
dofile("test_api/init.lua")

test_api.load_module(".","heatplace_api")

local heatplace = heatplace_api.heatplace:new()

heatplace:add_heatplace_part("fireplace", heatplace_api.heatplace_fireplace_finish({
    fuels = 4,
    slot1_capacity = 200000,
    fuel_volume_limit = 200000,
    air_flow_base = 800,
    air_flow_coef = 5,
    air_noflow = 200,
    air_amount = 1000000,
  }))
heatplace:add_heatplace_part("body", heatplace_api.heatplace_body_finish({
    heat_capacity = 2000*1000,
  }))
heatplace:add_heatplace_transport("fireplace->body", heatplace_api.heatplace_transport_finish({
    thermal_cond = 200,
    temp1_key = "fireplace_temp",
    temp2_key = "body_temp",
    heat1_cap = 700*1000,
    heat2_cap = 2000*1000,
  }))

local graph_structure = {
  ["Tempratures"] = {
    "fireplace_temp", --
    "body_temp", --
    "fireplace_fuel1_temp", --
    "fireplace_fuel2_temp", --
    "fireplace_fuel3_temp", --
    "fireplace_fuel4_temp", --
  },
  ["Amount"] = {
    "fireplace_fuel1_amount", --
    "fireplace_fuel2_amount", --
    "fireplace_fuel3_amount", --
    "fireplace_fuel4_amount", --
  },
}
local output = test_api.graph_empty_data(graph_structure)

local pos = {x=0,y=0,z=0}
local my_meta = test_api.meta:new()
local power = 1
local speed = 72
local steps = 1

local index = 1
local sim_div = speed * steps

-- nothing hapening start sequence
for i=1,100 do
  print("Index "..index)
  heatplace:step_heatplace(pos, my_meta, power, speed, steps)
  my_meta:insert_floats(graph_structure, "Tempratures", output, index)
  index = index + 1
end
-- establishing fire
local fireplace = heatplace:get_heatplace_part("fireplace")
local heatplace_data = heatplace:load_data(pos, my_meta)
local fuel_item = ItemStack("defualt:wood 3")
-- atmosohere heat capacity = 700
fuel_item:set_definition({
  _heatplace_fuel = {
    amount = 180000,
    volume_coef = 1,
    surface_coef = 0.2,
    heat_capacity = 10000,
    solid_oxygen_need = 700,
    solid_burn_energy = 500000000,
    solid_smoke_amount = 750,
    burning_temp = 280 + 273.15,
    burning_coef = 0.065,
    vapor_oxygen_need = 600,
    vapor_burn_energy = 600000000/375,
    vapor_amount = 375,
    vapor_smoke_amount = 2,
    sublimation_temp = 500 + 273.15,
    sublimation_heat = 40,
    sublimation_coef = 0.055,
    surface_thermal_cond_coef = 8000,
  },
})
fireplace:add_fuel(pos, my_meta, heatplace_data, fuel_item, 1, "singleplayer")
heatplace:save_data(pos, my_meta, heatplace_data)
local init_item = ItemStack("defualt:torch 1")
init_item:set_definition({
  _heatplace_igniter = {
    heat_per_use = 18000 + speed*150,
  },
})
for i=1,190+steps*2 do
  print("Index "..index)
  heatplace:step_heatplace(pos, my_meta, power, speed, steps)
  heatplace_data = heatplace:load_data(pos, my_meta)
  fireplace:ignite_fuel(pos, my_meta, heatplace_data, init_item, 1, "singleplayer")
  heatplace:save_data(pos, my_meta, heatplace_data)
  my_meta:insert_floats(graph_structure, "Tempratures", output, index)
  my_meta:insert_floats(graph_structure, "Amount", output, index)
  index = index + 1
end
-- burning
for i=1,250/sim_div do
  print("Index "..index)
  heatplace:step_heatplace(pos, my_meta, power, speed, steps)
  my_meta:insert_floats(graph_structure, "Tempratures", output, index)
  my_meta:insert_floats(graph_structure, "Amount", output, index)
  index = index + 1
end
for slot=2,4 do
  print("fuel to slot "..slot..", fuel count: "..fuel_item:get_count())
  heatplace_data = heatplace:load_data(pos, my_meta)
  fireplace:add_fuel(pos, my_meta, heatplace_data, fuel_item, slot, "singleplayer")
  heatplace:save_data(pos, my_meta, heatplace_data)
  for i=1,250/sim_div do
    print("Index "..index)
    heatplace:step_heatplace(pos, my_meta, power, speed, steps)
    my_meta:insert_floats(graph_structure, "Tempratures", output, index)
    my_meta:insert_floats(graph_structure, "Amount", output, index)
    index = index + 1
  end
end
for i=1,2000+5200/sim_div do
  print("Index "..index)
  heatplace:step_heatplace(pos, my_meta, power, speed, steps)
  my_meta:insert_floats(graph_structure, "Tempratures", output, index)
  my_meta:insert_floats(graph_structure, "Amount", output, index)
  index = index + 1
end

return output

