local creature = require "engine.mech.creature"
local player = {}

--- @class base_player: creature
--- @field fov_r integer

player.base = function()
  return Table.extend(creature.new(), {
    codename = "player",
    player_flag = true,
    fov_r = 15,

    ai = {
      next_action = nil,
      finish_turn = nil,
      run = function(entity, _)
        while true do
          if entity.ai.next_action then
            entity.ai.next_action:run(entity)
            entity.ai.next_action = nil
          end
          if not State.combat or entity.ai.finish_turn then break end
          coroutine.yield()
        end
        entity.ai.finish_turn = false
      end,
    },
  })
end

Ldump.mark(player, {}, ...)
return player
