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
    button_pressed = nil,
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
  active_frames_t = CompositeMap.new(),

  -- context --
  frame = {},
  alignment = {},
  font = {},
  is_linear = {},
  line_last_h = {},
}

local CURSORS = {
  normal = love.mouse.newCursor("engine/assets/sprites/gui/cursor.png"),
  hand = love.mouse.getSystemCursor("hand"),
}

local FRAME = "engine/assets/sprites/gui/button_frame.png"
local ACTIVE_FRAME = "engine/assets/sprites/gui/active_button_frame.png"

local SCALE = 4  -- TODO extract scale here & in view


----------------------------------------------------------------------------------------------------
-- [SECTION] Context
----------------------------------------------------------------------------------------------------

local get_font, get_batch, get_mouse_over

ui.start = function()
  love.mouse.setCursor(CURSORS.normal)

  model.selection.max_i = 0
  model.frame = {{
    x = 0,
    y = 0,
    w = love.graphics.getWidth(),
    h = love.graphics.getHeight(),
  }}
  model.alignment = {{x = "left", y = "top"}}
  model.font = {get_font(20)}
  model.is_linear = {false}
  model.line_last_h = {0}
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
  end
  if not y then
    y = 0
  end
  if not w then
    w = prev.w - x
  elseif w < 0 then
    w = prev.w + w
  end
  if not h then
    h = prev.h - y
  elseif h < 0 then
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
    Table.last(model.frame).y = pop.y + pop.h
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
  local font = get_font(size or 20)
  table.insert(model.font, font)
  love.graphics.setFont(font)
end

ui.finish_font = function()
  table.remove(model.font)
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
  for i = 0, lines - 1 do
    table.insert(result, text:utf_sub(i * chars_per_line + 1, (i + 1) * chars_per_line))
  end
  return result
end

--- @param text string
ui.text = function(text)
  local frame = Table.last(model.frame)
  local font = Table.last(model.font)
  local alignment = Table.last(model.alignment)

  local wrapped = wrap(text)

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
      dy = frame.h - font:getHeight() * #wrapped - font:getHeight() * (i - 1)
    end
    love.graphics.print(line, frame.x + dx, frame.y + dy)

    if alignment.y == "top" then
      frame.y = frame.y + font:getHeight() * 1.25
    end
  end
end

ui.br = function()
  ui.text(" ")
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
  end
end

local ACTIVE_FRAME_PERIOD = .1

--- @param image string|love.Image
--- @param key love.KeyConstant
--- @return {is_pressed: boolean, is_mouse_over: boolean}
ui.hot_button = function(image, key)
  image = get_image(image)
  local w = image:getWidth() * SCALE
  local h = image:getHeight() * SCALE
  local is_mouse_over = get_mouse_over(w, h)
  local is_pressed = (is_mouse_over and model.mouse.button_pressed)
    or Table.contains(model.keyboard.pressed, key)

  if is_pressed then
    model.active_frames_t:set(ACTIVE_FRAME_PERIOD, image, key)
  end

  local is_active = model.active_frames_t:get(image, key)

  local font_size, text, dy
  if key:utf_len() == 1 then
    font_size = 36
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

  if is_mouse_over or is_active then
    ui.start_frame(-SCALE, -SCALE, w + SCALE * 2, h + SCALE * 2)
      ui.tile(is_active and ACTIVE_FRAME or FRAME)
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

  return {
    is_pressed = is_pressed,
    is_mouse_over = is_mouse_over,
  }
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
end

--- @param options string[]
--- @return number?
ui.choice = function(options)
  local is_selected = false
  local font = Table.last(model.font)

  for i, option in ipairs(options) do
    if model.selection.max_i + i == model.selection.i then
      is_selected = true
      option = "> " .. option
    else
      option = "  " .. option
    end

    local is_mouse_over = get_mouse_over(font:getWidth(option), font:getHeight() * 1.25)

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
    -- TODO remove everything besides this
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

ui.handle_update = function(dt)
  for k, v in model.active_frames_t:iter() do
    local next_v = v - dt
    if next_v <= 0 then
      next_v = nil
    end
    model.active_frames_t:set(next_v, unpack(k))
  end
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

----------------------------------------------------------------------------------------------------
-- [SECTION] Footer
----------------------------------------------------------------------------------------------------

-- NOTICE no Ldump.mark, the module is never serialized
return ui
