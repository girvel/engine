local tcod = require("engine.tech.tcod")


local combat_ai = {}

--- @class combat_ai: ai
local methods = {}
local mt = {__index = methods}

--- @return combat_ai
combat_ai.new = function()
  return setmetatable({}, mt)
end

--- @param entity entity
--- @param dt integer
methods.control = function(entity, dt)
  if not State.combat then
    if State.hostility:get(entity, State.player)
      and tcod.snapshot(State.grids.solids):is_visible_unsafe(unpack(entity.position))
      and not State.player.ai.in_cutscene_flag
      and (State.player.position - entity.position):abs() <= State.player.fov_r * 0.6
    then
      State:start_combat({State.player, entity})
    end
  end
end

Ldump.mark(combat_ai, {}, ...)
return combat_ai
