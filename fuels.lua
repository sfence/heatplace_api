
-- list of common fuels with parameters

heatplace_api.fuels = {}

heatplace_api.fuels["default:wood"] = {
    amount = 1000000,
    heat_capacity = 1000,
    
    surface_coef = 1,
    volume_coef = 1,
    vapor_oxygen_need = 25,
    sublimation_temp = 260,
    solid_oxygen_need = 30,
    burning_temp = 500,
    
    sublimation_heat = 2000,
    sublimation_coef = 0.2,
    
    burning_coef = 0.05,
    
    vapor_burn_energy = 10000,
    solid_burn_energy = 9000,
    
    --temp_distribution = ?,
    --thermal_conductivity = ,
  }
