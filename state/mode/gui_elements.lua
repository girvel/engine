local sprite = require("engine.tech.sprite")


local ICON_ATLAS = love.graphics.newImage("engine/assets/sprites/gui/icons.png")

local nth = function(index)
  return love.graphics.newImage(sprite.utility.cut_out(
    ICON_ATLAS, sprite.utility.get_atlas_quad(index, 16, ICON_ATLAS:getDimensions())
  ))
end

local gui_elements = {
  skip_turn = nth(1),
  hand_attack = nth(6),
  offhand_attack = nth(7),
  journal = nth(17),
  journal_active = nth(18),
  escape_menu = nth(19),

  window_bg = "engine/assets/sprites/gui/window_bg.png",
  hp_bg = "engine/assets/sprites/gui/hp_bg.png",
  hp_bar = "engine/assets/sprites/gui/hp_bar.png",
}


Ldump.mark(gui_elements, {}, ...)
return gui_elements
