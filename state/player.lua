local action = require("engine.tech.action")
local creature = require "engine.mech.creature"
local sound    = require "engine.tech.sound"


local player = {}

--- @class base_player: entity
--- @field fov_r integer
--- @field ai player_ai
--- @field hears? dialogue_line
--- @field speaks? integer

--- @alias dialogue_line plain_dialogue_line | dialogue_options

--- @class plain_dialogue_line
--- @field type "plain_line"
--- @field source entity?
--- @field text string

--- @class dialogue_options
--- @field type "options"
--- @field options table<integer, string>

--- @class player_ai: ai
--- @field next_action action?
--- @field finish_turn true?

local YOUR_TURN = sound.multiple("engine/assets/sounds/your_move", .2)

player.base = function()
  local result = Table.extend(creature.mixin(), {
    codename = "player",
    player_flag = true,
    fov_r = 16,

    ai = {
      next_action = nil,
      finish_turn = nil,
      control = function(entity)
        if State.combat then
          YOUR_TURN:play()
        end

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

      observe = function(entity, dt)
        if State.combat and not Table.contains(State.combat.list, entity) then
          State:start_combat({entity})
        end
      end,
    },
  })

  return result
end

--- @type action
player.skip_turn = Table.extend({
  name = "Завершить ход",
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
