local sprite = require("engine.tech.sprite")


local ICON_ATLAS = love.graphics.newImage("engine/assets/sprites/gui/icons.png")

local nth = function(index)
  return love.graphics.newImage(sprite.utility.cut_out(
    ICON_ATLAS, sprite.utility.get_atlas_quad(index, 16, ICON_ATLAS:getDimensions())
  ))
end

local gui_elements = {
  skip_turn = nth(1),
  dash = nth(2),
  interact = nth(3),
  disengage = nth(4),
  hit_dice = nth(5),
  hand_attack = nth(6),
  offhand_attack = nth(7),
  shove = nth(8),

  skip_turn_inactive = nth(9),
  dash_inactive = nth(10),
  interact_inactive = nth(11),
  disengage_inactive = nth(12),
  hit_dice_inactive = nth(13),
  hand_attack_inactive = nth(14),
  offhand_attack_inactive = nth(15),
  shove_inactive = nth(16),

  journal = nth(17),
  escape_menu = nth(18),
  journal_inactive = nth(25),

  second_wind = nth(33),
  action_surge = nth(34),
  fighting_spirit = nth(35),
  great_weapon_master = nth(36),

  second_wind_inactive = nth(41),
  action_surge_inactive = nth(42),
  fighting_spirit_inactive = nth(43),
  great_weapon_master_inactive = nth(44),

  window_bg = "engine/assets/sprites/gui/window_bg.png",
  hp_bg = "engine/assets/sprites/gui/hp_bg.png",
  hp_bar = "engine/assets/sprites/gui/hp_bar.png",
  hp_bar_extra = "engine/assets/sprites/gui/hp_bar_extra.png",
  sidebar_block_bg = "engine/assets/sprites/gui/sidebar_block_bg.png",
}


Ldump.mark(gui_elements, {}, ...)
return gui_elements
