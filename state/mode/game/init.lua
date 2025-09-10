local game = {}

--- @alias gui_input_mode "normal"|"target"

--- @class state_mode_game
--- @field type "game"
--- @field input_mode gui_input_mode
--- @field _sprite_batches table<string, love.SpriteBatch>
--- @field _temp_canvas love.Canvas
local methods = {
  draw_entity = require("engine.state.mode.game.draw_entity"),
  draw_gui = require("engine.state.mode.game.draw_gui"),
  draw_grid = require("engine.state.mode.game.draw_grid"),
}

local mt = {__index = methods}

game.new = function()
  return setmetatable({
    type = "game",
    input_mode = "normal",
    _sprite_batches = Fun.iter(State.level.atlases)
      :map(function(layer, base_image) return layer, love.graphics.newSpriteBatch(base_image) end)
      :tomap(),
    _temp_canvas = love.graphics.newCanvas(),
  }, mt)
end

Ldump.mark(game, {}, ...)
return game
