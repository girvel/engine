local sprite       = require("engine.tech.sprite")


local ICON_ATLAS = love.graphics.newImage("engine/assets/sprites/gui/icons.png")

local nth = function(index)
  return sprite.utility.cut_out(
    ICON_ATLAS, sprite.utility.get_atlas_quad(index, 16, ICON_ATLAS:getDimensions())
  )
end

local gui_elements = {
  skip_turn = nth(1),
  journal = nth(17),

  sidebar_bg = "engine/assets/sprites/gui/sidebar_bg.png",
  hp_bg = "engine/assets/sprites/gui/hp_bg.png",
  hp_bar = "engine/assets/sprites/gui/hp_bar.png",
}


Ldump.mark(gui_elements, {}, ...)
return gui_elements
