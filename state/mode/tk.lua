local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")


local tk = {}

local PADDING = 40
local MAX_READABLE_W = 800

--- @param x integer|"center"
--- @param y integer|"center"
--- @param w integer|"max"|"read_max"
--- @param h integer|"max"
tk.start_window = function(x, y, w, h)
  assert(x == "center")
  assert(y == "center")

  --- @cast w integer
  if w == "max" then
    w = love.graphics.getWidth() - 4 * PADDING
  elseif w == "read_max" then
    w = math.min(love.graphics.getWidth() - 4 * PADDING, MAX_READABLE_W)
  end

  --- @cast h integer
  if h == "max" then
    h = love.graphics.getHeight() - 4 * PADDING
  end

  ui.start_frame(
    (love.graphics.getWidth() - w) / 2 - PADDING,
    (love.graphics.getHeight() - h) / 2 - PADDING,
    w + 2 * PADDING,
    h + 2 * PADDING
  )
    ui.tile(gui_elements.window_bg)
  ui.finish_frame()

  ui.start_frame(
    (love.graphics.getWidth() - w) / 2,
    (love.graphics.getHeight() - h) / 2,
    w, h
  )
end

tk.finish_window = function()
  ui.finish_frame()
end

--- @param entity entity
--- @param x integer
--- @param y integer
--- @param scale integer
tk.draw_entity = function(entity, x, y, scale)
  local display_slot, is_hand_bg, is_offhand_bg
  if entity.inventory then
    display_slot = function(slot)
      local this_item = entity.inventory[slot]
      if not this_item then return end

      local item_sprite = this_item.sprite
      local entity_anchor = entity.sprite.anchors[slot]
      local item_anchor = item_sprite.anchors.parent
      local item_x, item_y = x, y
      if entity_anchor and item_anchor then
        local offset = (entity_anchor - item_anchor):mul_mut(scale)
        item_x = item_x + offset[1]
        item_y = item_y + offset[2]
      end
      love.graphics.draw(item_sprite.image, item_x, item_y, 0, scale)
    end

    is_hand_bg = entity.direction == Vector.up
    is_offhand_bg = entity.direction ~= Vector.down

    if is_hand_bg then display_slot("hand") end
    if is_offhand_bg then display_slot("offhand") end
  end

  love.graphics.draw(entity.sprite.image, x, y, 0, scale)

  if entity.inventory then
    display_slot("body")
    display_slot("head")
    display_slot("blood")
    display_slot("gloves")
    if not is_hand_bg then display_slot("hand") end
    if not is_offhand_bg then display_slot("offhand") end
    display_slot("highlight")
  end
end

tk.action_button = function(action, hotkey)
  local is_available = action:is_available(State.player)
  local codename = is_available and action.codename or (action.codename .. "_inactive")
  if ui.hot_button(gui_elements[codename], hotkey, not is_available) then
    action:act(State.player)
  end
end

Ldump.mark(tk, {}, ...)
return tk
