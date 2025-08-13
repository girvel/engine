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
}

ui.start = function()
  model.selection.max_i = 0
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
    love.graphics.print(option, 0, 20 * (i - 1))
  end

  model.selection.max_i = model.selection.max_i + #options

  if model.selection.is_pressed and is_selected then
    return model.selection.i
  end
end

ui.finish = function()
  model.selection.is_pressed = false
end

ui.push_keypress = function(key)
  if key == "w" then
    model.selection.i = Math.loopmod(model.selection.i - 1, model.selection.max_i)
  elseif key == "s" then
    model.selection.i = Math.loopmod(model.selection.i + 1, model.selection.max_i)
  elseif key == "return" then
    model.selection.is_pressed = true
  end
end

return Ldump.mark(ui, {}, ...)
