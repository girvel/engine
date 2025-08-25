local action = require("engine.tech.action")
local creature = require "engine.mech.creature"


local player = {}

--- @class base_player: entity
--- @field fov_r integer
--- @field ai player_ai

--- @class player_ai: ai
--- @field next_action action?
--- @field finish_turn true?

player.base = function()
  local result = Table.extend(creature.mixin(), {
    codename = "player",
    player_flag = true,
    fov_r = 16,

    ai = {
      next_action = nil,
      finish_turn = nil,
      control = function(entity, _)
        while true do
          if entity.ai.next_action then
            entity.ai.next_action:act(entity)
            entity.ai.next_action = nil
          end
          if not State.combat or entity.ai.finish_turn then break end
          coroutine.yield()
        end
        entity.ai.finish_turn = false
      end,
    },
  })

  return result
end

--- @type action
player.skip_turn = Table.extend({
  codename = "skip_turn",

  _is_available = function(self, entity)
    return State.combat and State.combat:get_current() == entity
  end,
  _act = function(self, entity)
    entity.ai.finish_turn = true
    return true
  end,
}, action.base)

Ldump.mark(player, {}, ...)
return player
