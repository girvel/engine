local creature = require "engine.mech.creature"
local items    = require "levels.main.palette.items"
local player = {}

--- @class base_player: creature_mixin
--- @field fov_r integer

player.base = function()
  local result = Table.extend(creature.mixin(), {
    codename = "player",
    player_flag = true,
    fov_r = 15,
    base_hp = 10,

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

    inventory = {
      hand = items.knife(),
    },
  })

  creature.init(result)
  return result
end

Ldump.mark(player, {}, ...)
return player
