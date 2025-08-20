local sprite       = require("engine.tech.sprite")


local ICON_ATLAS = love.graphics.newImage("engine/assets/sprites/icons.png")

local gui_elements = {
  skip_turn = sprite.utility.cut_out(ICON_ATLAS, sprite.utility.get_atlas_quad(1, 16, ICON_ATLAS:getDimensions())),
  journal = sprite.utility.cut_out(ICON_ATLAS, sprite.utility.get_atlas_quad(17, 16, ICON_ATLAS:getDimensions())),
}


Ldump.mark(gui_elements, {}, ...)
return gui_elements
