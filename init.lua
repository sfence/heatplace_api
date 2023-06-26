
heatplace_api = {
  translate = minetest.get_translator("heatplace_api")
}

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/settings.lua")

dofile(modpath.."/functions.lua")

dofile(modpath.."/heatplace.lua")

dofile(modpath.."/body.lua")
dofile(modpath.."/transport.lua")
dofile(modpath.."/fireplace.lua")

