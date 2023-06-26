
-- emulation of burning

function heatplace_api.emulate_burning_step(part)
  -- precalculation
  local fuels_data = {}
  for fuel=1,part.fuels do
    local key_fuel = part.key.."_fuel"..fuel
    local amount = data[key_fuel.."_amount"]
    if (amount>0) then
      local fuel_data = {}
      
      local high_temp = data[key_fuel.."_high_temp_ratio"] or 0
      
      local amount_high = math.round(amount*high_temp)
      local amount_low = amount - amount_high
      
      local temp_key = key_fuel.."_temp"
      local temp = data[temp_key]
      fuel_data.heat_capacity = data[key_fuel.."_heat_capacity"]/speed
      fuel_data.surface_coef = data[key_fuel.."_surface_coef"]
      fuel_data.volume_coef = data[key_fuel.."_volume_coef"]
      
      fuel_data.vapor_oxygen_need = data[key_fuel.."_vapor_oxygen_need"]
      fuel_data.sublimation_temp = data[key_fuel.."_sublimation_temp"]
      
      fuel_data.solid_oxygen_need = data[key_fuel.."_solid_oxygen_need"]
      fuel_data.burning_temp = data[key_fuel.."_burning_temp"]
      
      table.insert(fuels_data, fuel_data)
      
      if (high_temp>0) then
        
        table.insert(fuels_data, fuel_data)
      end
    end
  end
  
  -- final calculation
  for _,part in pairs(help_parts) do
    
  end
end
