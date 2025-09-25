local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")
local item = require("engine.tech.item")


local tk = {}

local PADDING = 40
local MAX_READABLE_W = 800

--- @param x integer|"center"
--- @param y integer|"center"
--- @param w integer|"max"|"read_max"
--- @param h integer|"max"
tk.start_window = function(x, y, w, h)
  if w == "max" then
    w = love.graphics.getWidth() - 4 * PADDING
  elseif w == "read_max" then
    w = math.min(love.graphics.getWidth() - 4 * PADDING, MAX_READABLE_W)
  end --- @cast w integer

  if h == "max" then
    h = love.graphics.getHeight() - 4 * PADDING
  end --- @cast h integer

  if x == "center" then
    x = (love.graphics.getWidth() - w) / 2
  end --- @cast x integer

  if y == "center" then
    y = (love.graphics.getHeight() - h) / 2
  end --- @cast y integer

  ui.start_frame(
    x - PADDING,
    y - PADDING,
    w + 2 * PADDING,
    h + 2 * PADDING
  )
    ui.tile(gui_elements.window_bg)
  ui.finish_frame()

  ui.start_frame(x, y, w, h)
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
      if not item_sprite then return end

      local dx, dy = unpack(item.anchor_offset(entity, slot):mul_mut(scale * 16))
      local item_x = x + dx
      local item_y = y + dy
      love.graphics.draw(item_sprite.image, item_x, item_y, 0, scale)
    end

    is_hand_bg = entity.direction == Vector.up
    is_offhand_bg = entity.direction ~= Vector.down

    if is_hand_bg then display_slot("hand") end
    if is_offhand_bg then display_slot("offhand") end
  end

  love.graphics.draw(entity.sprite.image, x, y, entity.rotation or 0, scale)

  if entity.inventory then
    display_slot("tatoo")
    display_slot("body")
    display_slot("head")
    display_slot("blood")
    display_slot("gloves")
    display_slot("bag")
    if not is_hand_bg then display_slot("hand") end
    if not is_offhand_bg then display_slot("offhand") end
    display_slot("highlight")
  end
end

local SIDEBAR_BLOCK_PADDING = 10

--- @nodiscard
tk.start_block = function()
  local frame = ui.get_frame()
  ui.start_frame(
    4 + SIDEBAR_BLOCK_PADDING, 4 + SIDEBAR_BLOCK_PADDING,
    -2 * SIDEBAR_BLOCK_PADDING - 8
  )
  return frame
end

tk.finish_block = function(start)
  local finish = ui.get_frame()
  ui.finish_frame()

  local h = finish.y - start.y + SIDEBAR_BLOCK_PADDING + 4
  ui.start_frame(-16, -16, start.w + 32, h + 32)
    ui.tile(gui_elements.sidebar_block_bg)
  ui.finish_frame()
  ui.offset(0, h)
end

tk.choose_save = function(show_new_save)
  local options = {}
  local dates = {}

  for _, name in ipairs(love.filesystem.getDirectoryItems("saves")) do
    local full_path = "saves/" .. name
    if love.filesystem.getInfo(full_path).type ~= "file" or
      not name:ends_with(".ldump.gz")
    then
      goto continue
    end

    name = name:sub(1, -10)
    table.insert(options, name)
    dates[name] = love.filesystem.getInfo(full_path).modtime

    ::continue::
  end

  table.sort(options, function(a, b) return dates[a] > dates[b] end)
  if show_new_save then
    table.insert(options, 1, "<новое сохранение>")
  end

  local i = ui.choice(options)
  if show_new_save and i == 1 then
    return "save_" .. os.date("%Y-%m-%d_%H-%M-%S")
  end
  return options[i]
end

Ldump.mark(tk, {}, ...)
return tk
