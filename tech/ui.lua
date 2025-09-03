local sprite = require "engine.tech.sprite"
--- Immediate mode UI module
local ui = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Internal state
----------------------------------------------------------------------------------------------------

local model = {
  -- input state --
  mouse = {
    x = 0,
    y = 0,
    button_pressed = {},
    button_released = {},
  },
  keyboard = {
    pressed = {},
  },

 -- accumulated state --
  selection = {
    i = 1,
    max_i = 0,
    is_pressed = false,
  },
  cursor = nil,

  -- state --
  active_frames_t = CompositeMap.new(),
  are_pressed = CompositeMap.new(),  -- TODO weak pointer here

  -- context --
  frame = {},
  alignment = {},
  font = {},
  font_size = {},
  is_linear = {},
  line_last_h = {},
}

local CURSORS = {
  normal = love.mouse.newCursor("engine/assets/sprites/gui/cursor.png"),
  hand = love.mouse.getSystemCursor("hand"),
}

local FRAME = "engine/assets/sprites/gui/button_frame.png"
local ACTIVE_FRAME = "engine/assets/sprites/gui/active_button_frame.png"

local SCALE = 4  -- TODO extract scale here

local get_font, get_batch, get_mouse_over, button


----------------------------------------------------------------------------------------------------
-- [SECTION] Context
----------------------------------------------------------------------------------------------------

ui.start = function()
  model.selection.max_i = 0
  model.cursor = "normal"
  model.frame = {{
    x = 0,
    y = 0,
    w = love.graphics.getWidth(),
    h = love.graphics.getHeight(),
  }}
  model.alignment = {{x = "left", y = "top"}}
  model.font = {get_font(20)}
  model.font_size = {20}
  model.is_linear = {false}
  model.line_last_h = {0}
end

ui.finish = function()
  assert(#model.frame == 1, "Unclosed UI frame(s) (%s)" % {#model.frame})
  model.selection.is_pressed = false
  model.mouse.button_pressed = {}
  model.mouse.button_released = {}
  model.keyboard.pressed = {}
  love.mouse.setCursor(CURSORS[model.cursor])
end

--- @param x? integer?
--- @param y? integer?
--- @param w? integer?
--- @param h? integer?
ui.start_frame = function(x, y, w, h)
  local prev = Table.last(model.frame)
  if not x then
    x = 0
  end
  if not y then
    y = 0
  end
  if not w then
    w = prev.w - x
  elseif w <= 0 then
    w = prev.w + w
  end
  if not h then
    h = prev.h - y
  elseif h <= 0 then
    h = prev.h + h
  end
  table.insert(model.frame, {
    x = prev.x + x,
    y = prev.y + y,
    w = w,
    h = h,
  })
end

--- @param push_y? boolean
ui.finish_frame = function(push_y)
  local pop = table.remove(model.frame)
  if push_y then
    local this = Table.last(model.frame)
    local next_y = pop.y + pop.h
    this.h = this.h - (next_y - this.y)
    this.y = next_y
  end
end

--- @param x? "left"|"center"|"right"
--- @param y? "top"|"center"|"bottom"
ui.start_alignment = function(x, y)
  local prev = Table.last(model.alignment)
  table.insert(model.alignment, {x = x or prev.x, y = y or prev.y})
end

ui.finish_alignment = function()
  table.remove(model.alignment)
end

--- @param size? integer
ui.start_font = function(size)
  size = size or 20
  local font = get_font(size)
  table.insert(model.font, font)
  table.insert(model.font_size, size)
  love.graphics.setFont(font)
end

ui.finish_font = function()
  table.remove(model.font)
  table.remove(model.font_size)
  love.graphics.setFont(Table.last(model.font))
end

ui.start_line = function()
  ui.start_frame()
  table.insert(model.is_linear, true)
  table.insert(model.line_last_h, 0)
end

ui.finish_line = function()
  table.remove(model.is_linear)
  local old_frame = Table.last(model.frame)
  ui.finish_frame()
  Table.last(model.frame).y = old_frame.y + table.remove(model.line_last_h)
end

----------------------------------------------------------------------------------------------------
-- [SECTION] UI elements
----------------------------------------------------------------------------------------------------

local wrap = function(text)
  local result = {}

  local effective_w = Table.last(model.frame).w
  local font_w = Table.last(model.font):getWidth("w")
  local chars_per_line = math.floor(effective_w / font_w)

  local lines = math.ceil(text:utf_len() / chars_per_line)
  if lines == 0 then
    return {""}
  end
  for i = 0, lines - 1 do
    table.insert(result, text:utf_sub(i * chars_per_line + 1, (i + 1) * chars_per_line))
  end
  return result
end

--- @param text any
ui.text = function(text)
  text = tostring(text)

  local frame = Table.last(model.frame)
  local font = Table.last(model.font)
  local alignment = Table.last(model.alignment)
  local is_linear = Table.last(model.is_linear)

  local wrapped = wrap(text)

  if is_linear then
    assert(#wrapped == 1)
  end

  for i, line in ipairs(wrapped) do
    local dx = 0
    local dy = 0
    if alignment.x == "center" then
      dx = (frame.w - font:getWidth(line)) / 2
    elseif alignment.x == "right" then
      dx = frame.w - font:getWidth(line)
    end
    if alignment.y == "center" then
      dy = (frame.h - font:getHeight() * #wrapped) / 2 + font:getHeight() * (i - 1)
    elseif alignment.y == "bottom" then
      dy = frame.h - font:getHeight() * #wrapped + font:getHeight() * (i - 1)
    end
    love.graphics.print(line, frame.x + dx, frame.y + dy)

    if alignment.y == "top" then
      if is_linear then
        frame.x = frame.x + font:getWidth(text)
        model.line_last_h[#model.line_last_h] = math.max(
          Table.last(model.line_last_h),
          font:getHeight() * 1.25
        )
      else
        frame.y = frame.y + font:getHeight() * 1.25
        frame.h = frame.h - font:getHeight() * 1.25
      end
    end
  end
end

ui.br = function()
  ui.text(" ")
end

ui.separator = function()
  local frame = Table.last(model.frame)
  local font = Table.last(model.font)
  ui.text("-" * math.floor(frame.w / font:getWidth("w")))
end

--- @param text string
ui.h1 = function(text)
  local font_size = Table.last(model.font_size)

  ui.start_font(font_size * 2)
  ui.start_alignment("center")
    ui.text(text)
    ui.br()
  ui.finish_alignment()
  ui.finish_font()
end

--- @param headers string[]
--- @param content any[][]
ui.table = function(headers, content)
  local frame = Table.last(model.frame)
  local font = Table.last(model.font)

  for y, row in ipairs(content) do
    for x, value in ipairs(row) do
      content[y][x] = tostring(value)
    end
  end

  local original_column_sizes = Fun.range(#headers)
    :map(function(x)
      return math.max(
        headers[x]:utf_len(),
        #content == 0 and 0 or Fun.range(#content)
          :map(function(y) return content[y][x]:utf_len() end)
          :max())
    end)
    :totable()

  local original_w = Fun.iter(original_column_sizes):sum()
  local total_w = math.floor(frame.w / font:getWidth("i"))
  local k = total_w / original_w

  local column_sizes = Fun.iter(original_column_sizes)
    :map(function(w) return math.floor(w * k) - 2 end)
    :totable()

  ui.text(Fun.iter(headers)
    :enumerate()
    :map(function(x, h) return h .. " " * (column_sizes[x] - h:utf_len()) .. "  " end)
    :reduce(Fun.op.concat, ""))

  ui.text("-" * (total_w))

  for _, row in ipairs(content) do
    ui.text(Fun.iter(row)
      :enumerate()
      :map(function(x, v) return "  " .. v .. " " * (column_sizes[x] - v:utf_len()) end)
      :reduce(Fun.op.concat, "")
      :utf_sub(3))
  end
end

local get_image = function(base)
  if type(base) == "string" then
    return love.graphics.newImage(base)  -- NOTICE cached by kernel
  end
  return base
end

--- @param image string|love.Image
ui.image = function(image)
  local frame = Table.last(model.frame)
  local is_linear = Table.last(model.is_linear)

  image = get_image(image)
  love.graphics.draw(image, frame.x, frame.y, 0, SCALE)
  if is_linear then
    frame.x = frame.x + image:getWidth() * SCALE
    model.line_last_h[#model.line_last_h] = math.max(
      Table.last(model.line_last_h),
      image:getHeight() * SCALE
    )
  else
    frame.y = frame.y + image:getHeight() * SCALE
    frame.h = frame.h - image:getHeight() * SCALE
  end
end

local ACTIVE_FRAME_PERIOD = .1

--- @param image string|love.Image
--- @param key love.KeyConstant
--- @return ui_button_out
ui.key_button = function(image, key, is_disabled)
  image = get_image(image)
  local w = image:getWidth() * SCALE
  local h = image:getHeight() * SCALE
  local result = button(w, h)

  if is_disabled then
    result.is_clicked = false
  else
    result.is_clicked = result.is_clicked or Table.contains(model.keyboard.pressed, key)
  end

  if result.is_mouse_over and not is_disabled then
    model.cursor = "hand"
  end

  if result.is_clicked then
    model.active_frames_t:set(ACTIVE_FRAME_PERIOD, image, key)
  end

  result.is_active = result.is_active or model.active_frames_t:get(image, key)

  local font_size, text, dy
  if key:utf_len() == 1 then
    font_size = 32
    text = key:utf_upper()
    dy = SCALE
  else
    font_size = 20
    text = key
    dy = 0
  end

  ui.start_frame()
    ui.image(image)
    local frame_image = Table.last(model.frame)
  ui.finish_frame()

  if (result.is_mouse_over and not is_disabled) or result.is_active then
    ui.start_frame(-SCALE, -SCALE, w + SCALE * 2, h + SCALE * 2)
      ui.tile(result.is_active and ACTIVE_FRAME or FRAME)
    ui.finish_frame()
  end

  ui.start_font(font_size)
  ui.start_frame(nil, nil, w - SCALE, h + dy)
  ui.start_alignment("right", "bottom")
    ui.text(text)
  ui.finish_alignment()
  ui.finish_frame()
  ui.finish_font()

  local frame = Table.last(model.frame)
  frame.x = frame_image.x
  frame.y = frame_image.y

  return result
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

--- @param x? integer
--- @param y? integer
ui.offset = function(x, y)
  local frame = Table.last(model.frame)
  frame.x = frame.x + (x or 0)
  frame.y = frame.y + (y or 0)
  frame.w = frame.w - (x or 0)
  frame.h = frame.h - (y or 0)
end

--- @param options string[]
--- @return number?
ui.choice = function(options)
  local is_selected = false
  local font = Table.last(model.font)
  local frame = Table.last(model.frame)

  for i, option in ipairs(options) do
    local button_out = button(frame.w, font:getHeight() * 1.25)

    if button_out.is_mouse_over then
      model.selection.i = model.selection.max_i + i
      is_selected = true
      model.cursor = "hand"
      love.graphics.setColor(.7, .7, .7)
    end

    if model.selection.max_i + i == model.selection.i then
      is_selected = true
      if button_out.is_active then
        option = "- " .. option
      else
        option = "> " .. option
      end
    else
      option = "  " .. option
    end

    if button_out.is_clicked then
      return model.selection.i
    end

    ui.text(option)

    if button_out.is_mouse_over then
      love.graphics.setColor(1, 1, 1)
    end
  end

  model.selection.max_i = model.selection.max_i + #options

  if model.selection.is_pressed and is_selected then
    return model.selection.i
  end
end

--- @param ... love.KeyConstant
--- @return boolean
ui.keyboard = function(...)
  for i = 1, select("#", ...) do
    if Table.contains(model.keyboard.pressed, select(i, ...)) then
      return true
    end
  end
  return false
end

ui.mousedown = function()
  return Table.contains(model.mouse.button_pressed, 1)
end

-- --- @param is_global? boolean use all screen instead of current frame
-- --- @return boolean
-- ui.mouse = function(is_global)
--   if is_global then
--     table.insert(model.frame, {
--       x = 0, y = 0,
--       w = love.graphics.getWidth(), h = love.graphics.getHeight()
--     })
--   end
--   local frame = Table.last(model.frame)
--   local result = button(frame.w, frame.h).is_clicked
--   if is_global then
--     table.remove(model.frame)
--   end
--   return result
-- end

ui.get_frame = function()
  return Table.shallow_copy(Table.last(model.frame))
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
    -- TODO remove everything besides this
    table.insert(model.keyboard.pressed, key)
  end
end

ui.handle_mousemove = function(x, y)
  model.mouse.x = x
  model.mouse.y = y
end

ui.handle_mousepress = function(button)
  table.insert(model.mouse.button_pressed, button)
end

ui.handle_mouserelease = function(button)
  table.insert(model.mouse.button_released, button)
end

ui.handle_update = function(dt)
  for k, v in model.active_frames_t:iter() do
    local next_v = v - dt
    if next_v <= 0 then
      next_v = nil
    end
    model.active_frames_t:set(next_v, unpack(k))
  end
end

ui.handle_selection_reset = function()
  model.selection.i = 1
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

get_mouse_over = function(w, h)
  local frame = Table.last(model.frame)
  return (
    model.mouse.x > frame.x
    and model.mouse.y > frame.y
    and model.mouse.x <= frame.x + w
    and model.mouse.y <= frame.y + h
  )
end

--- @class ui_button_out
--- @field is_clicked boolean
--- @field is_active boolean
--- @field is_mouse_over boolean

--- @param w integer
--- @param h integer
--- @return ui_button_out
button = function(w, h)
  local frame = Table.last(model.frame)
  local x = frame.x
  local y = frame.y
  local result = {
    is_clicked = false,
    is_mouse_over = get_mouse_over(w, h),
  }

  result.is_active = result.is_mouse_over and model.are_pressed:get(x, y, w, h)

  if result.is_mouse_over then
    if Table.contains(model.mouse.button_pressed, 1) then
      model.are_pressed:set(true, x, y, w, h)
    end

    if Table.contains(model.mouse.button_released, 1)
      and model.are_pressed:get(x, y, w, h)
    then
      result.is_clicked = true
      model.are_pressed:set(false, x, y, w, h)
    end
  else
    if Table.contains(model.mouse.button_released, 1) then
      model.are_pressed:set(false, x, y, w, h)
    end
  end

  return result
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Footer
----------------------------------------------------------------------------------------------------

Ldump.mark(ui, {}, ...)
return ui
