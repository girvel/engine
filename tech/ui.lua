--- Immediate mode UI
local ui = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Internal state
----------------------------------------------------------------------------------------------------

local model = {
  selection = {
    i = 1,
    max_i = 0,
    is_pressed = false,
  },
  mouse = {
    x = 0,
    y = 0,
    button_pressed = nil,
  },
  rect = {},
  font = nil --[[@as love.Font]],
  line_h = nil --[[@as integer]],
}

local CURSORS = {
  normal = love.mouse.newCursor("engine/assets/sprites/cursor.png"),
  hand = love.mouse.getSystemCursor("hand"),
}


----------------------------------------------------------------------------------------------------
-- [SECTION] UI elements
----------------------------------------------------------------------------------------------------

ui.start = function()
  ui.font_size()
  ui.rect()
  love.mouse.setCursor(CURSORS.normal)

  model.selection.max_i = 0
  model.rect.x = 0
  model.rect.y = 0
  model.rect.w = love.graphics.getWidth()
  model.rect.h = love.graphics.getHeight()
end

ui.finish = function()
  model.selection.is_pressed = false
  model.mouse.button_pressed = nil
end

local PADDING = 10

--- @param x? integer?
--- @param y? integer?
--- @param w? integer?
--- @param h? integer?
ui.rect = function(x, y, w, h)
  model.rect.x = (x or 0) % love.graphics.getWidth() + PADDING
  model.rect.y = (y or 0) % love.graphics.getHeight() + PADDING
  model.rect.w = w or (love.graphics.getWidth() - model.rect.x) - PADDING
  model.rect.h = h or (love.graphics.getHeight() - model.rect.y) - PADDING
end

local font = Memoize(function(size)
  return love.graphics.newFont("engine/assets/fonts/clacon2.ttf", size)
end)

--- @param size? integer
ui.font_size = function(size)
  model.font = font(size or 20)
  model.line_h = math.floor(model.font:getHeight() * 1.25)
  love.graphics.setFont(model.font)
end

local wrap = function(text)
  local result = {}
  local chars_per_line = math.floor(model.rect.w / model.font:getWidth("w"))
  local lines = math.ceil(text:utf_len() / chars_per_line)
  for i = 0, lines - 1 do
    table.insert(result, text:sub(i * chars_per_line + 1, (i + 1) * chars_per_line))
  end
  return result
end

--- @param text string
ui.text = function(text)
  for _, line in ipairs(wrap(text)) do
    love.graphics.print(line, model.rect.x, model.rect.y)
    model.rect.y = model.rect.y + model.line_h
  end
end

ui.br = function()
  model.rect.y = model.rect.y + model.line_h
end

--- @param options string[]
--- @return number?
ui.choice = function(options)
  local is_selected = false
  for i, option in ipairs(options) do
    if model.selection.max_i + i == model.selection.i then
      is_selected = true
      option = "> " .. option
    else
      option = "  " .. option
    end

    local is_mouse_over = (
      model.mouse.x > model.rect.x
      and model.mouse.y > model.rect.y
      and model.mouse.y <= model.rect.y + model.line_h
      and model.mouse.x <= model.rect.x + model.font:getWidth(option)
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

----------------------------------------------------------------------------------------------------
-- [SECTION] Event handlers
----------------------------------------------------------------------------------------------------

ui.handle_keypress = function(key)
  if key == "w" then
    model.selection.i = Math.loopmod(model.selection.i - 1, model.selection.max_i)
  elseif key == "s" then
    model.selection.i = Math.loopmod(model.selection.i + 1, model.selection.max_i)
  elseif key == "return" then
    model.selection.is_pressed = true
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
-- [SECTION] Footer
----------------------------------------------------------------------------------------------------

-- TODO would it retain state on loading a save?
Ldump.mark(ui, {}, ...)
return ui
