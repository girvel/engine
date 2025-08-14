local ui = require("engine.tech.ui")

local game = {}

--- @class state_mode_game
local methods = {}
local mt = {__index = methods}

game.new = function()
  return setmetatable({
    
  }, mt)
end

methods.draw_gui = function()
  ui.text("<game>")
end

methods.draw_entity = function(self, entity)
  love.graphics.draw(entity.sprite.image, unpack(entity.position))
end

return Ldump.mark(game, {}, ...)
