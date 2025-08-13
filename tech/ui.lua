--- Immediate mode UI
local ui = {}

-- TODO move to initialization
local FONT = love.graphics.newFont("engine/assets/fonts/clacon2.ttf", 20)
love.graphics.setFont(FONT)

local current_choice = 1
local return_pressed = false

--- @param options string[]
--- @return number?
ui.choice = function(options)
  for i, option in ipairs(options) do
    if i == current_choice then
      option = "> " .. option
    else
      option = "  " .. option
    end
    love.graphics.print(option, 0, 20 * (i - 1))
  end

  if return_pressed then
    return current_choice
  end
end

ui.finish = function()
  return_pressed = false
end

ui.push_keypress = function(key)
  if key == "w" then
    current_choice = current_choice - 1
  elseif key == "s" then
    current_choice = current_choice + 1
  elseif key == "return" then
    return_pressed = true
  end
end

return ui
