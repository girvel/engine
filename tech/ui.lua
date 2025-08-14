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
}

ui.start = function()
  model.selection.max_i = 0
end

ui.finish = function()
  model.selection.is_pressed = false
  model.mouse.button_pressed = nil
end

--- @param text string
ui.text = function(text)
  love.graphics.print(text, 0, 0)
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

    love.graphics.print(option, 0, 20 * (i - 1))
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
return Ldump.mark(ui, {}, ...)
