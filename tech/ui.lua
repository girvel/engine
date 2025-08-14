--- Immediate mode UI
local ui = {}

-- TODO learn about transforms

-- TODO move to initialization
local FONT = love.graphics.newFont("engine/assets/fonts/clacon2.ttf", 20)
love.graphics.setFont(FONT)

local model = {
  selection = {
    i = 1,
    max_i = 0,
    is_pressed = false,
  },
  mouse = {
    position = Vector.zero,
    button_pressed = nil,
  },
  rect = {},
}

ui.start = function()
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

--- @param x? integer?
--- @param y? integer?
--- @param w? integer?
--- @param h? integer?
ui.rect = function(x, y, w, h)
  model.rect.x = (x or 0) % love.graphics.getWidth()
  model.rect.y = (y or 0) % love.graphics.getHeight()
  model.rect.w = w or (love.graphics.getWidth() - model.rect.x)
  model.rect.h = h or (love.graphics.getHeight() - model.rect.y)
end

--- @param text string
ui.text = function(text)
  love.graphics.print(text, model.rect.x, model.rect.y)
  model.rect.y = model.rect.y + 20
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

    -- TODO cursor change
    if model.mouse.position > V(0, 20 * (i - 1))
      and model.mouse.position < V(FONT:getWidth(option), 20 * i)
    then
      model.selection.i = model.selection.max_i + i
      if model.mouse.button_pressed then
        return model.selection.i
      end
      is_selected = true
    end

    ui.text(option)
  end

  model.selection.max_i = model.selection.max_i + #options

  if model.selection.is_pressed and is_selected then
    return model.selection.i
  end
end

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
  model.mouse.position = V(x, y)
end

ui.handle_mousepress = function(button)
  model.mouse.button_pressed = button
end

-- TODO would it retain state on loading a save?
Ldump.mark(ui, {}, ...)
return ui
