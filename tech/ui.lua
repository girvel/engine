local sprite = require "engine.tech.sprite"
--- Immediate mode UI module
local ui = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Internal state
----------------------------------------------------------------------------------------------------

local model = {
  mouse = {
    x = 0,
    y = 0,
    button_pressed = nil,
  },
  keyboard = {
    pressed = {},
  },

  selection = {
    i = 1,
    max_i = 0,
    is_pressed = false,
  },

  frame = {},
  center = {},
  font = {},
  padding = {},
}

local CURSORS = {
  normal = love.mouse.newCursor("engine/assets/sprites/cursor.png"),
  hand = love.mouse.getSystemCursor("hand"),
}

local SCALE = 4  -- TODO extract scale here & in view


----------------------------------------------------------------------------------------------------
-- [SECTION] UI elements
----------------------------------------------------------------------------------------------------

local get_font, get_batch

ui.start = function()
  love.mouse.setCursor(CURSORS.normal)

  model.selection.max_i = 0
  model.frame = {{
    x = 0,
    y = 0,
    w = love.graphics.getWidth(),
    h = love.graphics.getHeight(),
  }}
  model.center = {false}
  model.font = {get_font(20)}
  model.padding = {10}
end

ui.finish = function()
  model.selection.is_pressed = false
  model.mouse.button_pressed = nil
  model.keyboard.pressed = {}
end

--- @param x? integer?
--- @param y? integer?
--- @param w? integer?
--- @param h? integer?
ui.start_frame = function(x, y, w, h)
  local prev = Table.last(model.frame)
  if not x then
    x = 0
  elseif x < 0 then
    x = x % prev.w
  end
  if not y then
    y = 0
  elseif y < 0 then
    y = y % prev.h
  end
  if not w then
    w = prev.w - x
  end
  if not h then
    h = prev.h - y
  end
  table.insert(model.frame, {
    x = prev.x + x,
    y = prev.y + y,
    w = w,
    h = h,
  })
end

ui.finish_frame = function()
  table.remove(model.frame)
end

--- @param value integer?
ui.start_padding = function(value)
  table.insert(model.padding, value)
end

ui.finish_padding = function()
  table.remove(model.padding)
end

--- @param value boolean
ui.start_center = function(value)
  table.insert(model.center, value)
end

ui.finish_center = function()
  table.remove(model.center)
end

--- @param size? integer
ui.start_font = function(size)
  local font = get_font(size or 20)
  table.insert(model.font, font)
  love.graphics.setFont(font)
end

ui.finish_font = function()
  table.remove(model.font)
  love.graphics.setFont(Table.last(model.font))
end

local wrap = function(text)
  local result = {}

  local effective_w = Table.last(model.frame).w - 2 * Table.last(model.padding)
  local font_w = Table.last(model.font):getWidth("w")
  local chars_per_line = math.floor(effective_w / font_w)

  local lines = math.ceil(text:utf_len() / chars_per_line)
  for i = 0, lines - 1 do
    table.insert(result, text:utf_sub(i * chars_per_line + 1, (i + 1) * chars_per_line))
  end
  return result
end

--- @param text string
ui.text = function(text)
  local frame = Table.last(model.frame)
  local padding = Table.last(model.padding)
  local font = Table.last(model.font)
  local center = Table.last(model.center)

  for _, line in ipairs(wrap(text)) do
    local dx = 0
    if center then
      dx = (frame.w - font:getWidth(line)) / 2 - padding
    end
    love.graphics.print(line, frame.x + dx + padding, frame.y + padding)
    frame.y = frame.y + font:getHeight() * 1.25
  end
end

ui.br = function()
  ui.text(" ")
end

--- @param headers string[]
--- @param content any[][]
ui.table = function(headers, content)
  for y, row in ipairs(content) do
    for x, value in ipairs(row) do
      content[y][x] = tostring(value)
    end
  end

  local column_sizes = Fun.range(#headers)
    :map(function(x)
      return math.max(
        headers[x]:utf_len(),
        #content == 0 and 0 or Fun.range(#content)
          :map(function(y) return content[y][x]:utf_len() end)
          :max())
    end)
    :totable()

  ui.text(Fun.iter(headers)
    :enumerate()
    :map(function(x, h) return h .. " " * (column_sizes[x] - h:utf_len()) .. "  " end)
    :reduce(Fun.op.concat, ""))

  ui.text("-" * (Fun.iter(column_sizes):sum() + 2 * #column_sizes - 2))

  for _, row in ipairs(content) do
    ui.text(Fun.iter(row)
      :enumerate()
      :map(function(x, v) return "  " .. v .. " " * (column_sizes[x] - v:utf_len()) end)
      :reduce(Fun.op.concat, "")
      :utf_sub(3))
  end
end

--- @param path string
ui.image = function(path)
  local frame = Table.last(model.frame)
  local image = love.graphics.newImage(path)  -- NOTICE cached by kernel
  love.graphics.draw(image, frame.x, frame.y, 0, SCALE)
  frame.y = frame.y + image:getHeight() * SCALE
end

--- @param path string path to atlas file
ui.tile = function(path)
  local batch, quads, cell_size = get_batch(path)
  batch:clear()

  local frame = Table.last(model.frame)

  local cropped_w = math.ceil(frame.w / cell_size / SCALE) - 2
  local cropped_h = math.ceil(frame.h / cell_size / SCALE) - 2
  local end_x = frame.w / SCALE - cell_size
  local end_y = frame.h / SCALE - cell_size

  for x = 0, cropped_w do
    for y = 0, cropped_h do
      local quad_i
      if x == 0 then
        if y == 0 then
          quad_i = 1
        else
          quad_i = 4
        end
      else
        if y == 0 then
          quad_i = 2
        else
          quad_i = 5
        end
      end
      batch:add(quads[quad_i], x * cell_size, y * cell_size)
    end
  end

  for y = 0, cropped_h do
    local quad_i
    if y == 0 then
      quad_i = 3
    else
      quad_i = 6
    end
    batch:add(quads[quad_i], end_x, y * cell_size)
  end

  for x = 0, cropped_w do
    local quad_i
    if x == 0 then
      quad_i = 7
    else
      quad_i = 8
    end
    batch:add(quads[quad_i], x * cell_size, end_y)
  end

  batch:add(quads[9], end_x, end_y)

  love.graphics.draw(batch, frame.x, frame.y, 0, SCALE)
end

--- @param options string[]
--- @return number?
ui.choice = function(options)
  local is_selected = false
  local frame = Table.last(model.frame)
  local font = Table.last(model.font)

  for i, option in ipairs(options) do
    if model.selection.max_i + i == model.selection.i then
      is_selected = true
      option = "> " .. option
    else
      option = "  " .. option
    end

    local is_mouse_over = (
      model.mouse.x > frame.x
      and model.mouse.y > frame.y
      and model.mouse.y <= frame.y + font:getHeight() * 1.25
      and model.mouse.x <= frame.x + font:getWidth(option)
    )

    if is_mouse_over then
      model.selection.i = model.selection.max_i + i
      if model.mouse.button_pressed then
        return model.selection.i
      end
      is_selected = true
      love.mouse.setCursor(CURSORS.hand)
      love.graphics.setColor(.7, .7, .7)
    end

    ui.text(option)

    if is_mouse_over then
      love.graphics.setColor(1, 1, 1)
    end
  end

  model.selection.max_i = model.selection.max_i + #options

  if model.selection.is_pressed and is_selected then
    return model.selection.i
  end
end

--- @param key love.KeyConstant
ui.keyboard = function(key)
  return Table.contains(model.keyboard.pressed, key)
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Event handlers
----------------------------------------------------------------------------------------------------

ui.handle_keypress = function(key)
  if key == "up" then
    model.selection.i = Math.loopmod(model.selection.i - 1, model.selection.max_i)
  elseif key == "down" then
    model.selection.i = Math.loopmod(model.selection.i + 1, model.selection.max_i)
  elseif key == "return" then
    model.selection.is_pressed = true
  else
    table.insert(model.keyboard.pressed, key)
  end
end

ui.handle_mousemove = function(x, y)
  model.mouse.x = x
  model.mouse.y = y
end

ui.handle_mousepress = function(button)
  model.mouse.button_pressed = button
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Internals
----------------------------------------------------------------------------------------------------

get_font = Memoize(function(size)
  return love.graphics.newFont("engine/assets/fonts/clacon2.ttf", size)
end)

get_batch = Memoize(function(path)
  local image = love.graphics.newImage(path)
  local batch = love.graphics.newSpriteBatch(image)
  local w, h = image:getDimensions()
  assert(w == h)
  local cell_size = w / 3

  local quads = {}
  for i = 1, 9 do
    quads[i] = sprite.utility.get_atlas_quad(i, cell_size, w, h)
  end

  return batch, quads, cell_size
end)

----------------------------------------------------------------------------------------------------
-- [SECTION] Footer
----------------------------------------------------------------------------------------------------

-- NOTICE no Ldump.mark, the module is never serialized
return ui
