local state = {}

--- @class state
--- @field mode state_mode
--- @field _world table
--- @field _entities table
local state_methods = {
  --- Modifies entity
  --- @generic T
  --- @param self state
  --- @param entity T
  --- @param ... table extensions
  --- @return T
  add = function(self, entity, ...)
    Table.extend(entity, ...)
    self._world:add(entity)
    self._entities[entity] = true
    -- if entity.position and entity.layer then
    --   level.put(entity)
    -- end
    -- if entity.inventory then
    --   Fun.iter(entity.inventory)
    --     :each(function(slot, it) self:add(it) end)
    -- end
    Query(entity):on_add()
    return entity
  end,

  --- @async
  --- @param path string
  load_level = function(self, path)
    self:add {
      sprite = {
        image = love.graphics.newImage("engine/assets/sprites/moose_dude.png"),
      },
      position = V(64, 64),
    }
    local t = love.timer.getTime()
    while love.timer.getTime() - t < 3 do
      coroutine.yield()
    end
  end,
}
state.mt = {__index = state_methods}

--- @param systems table[]
--- @return state
state.new = function(systems)
  return setmetatable({
    mode = require("engine.state.mode").new(),

    _world = Tiny.world(unpack(systems)),
    _entities = {},
  }, state.mt)
end

return Ldump.mark(state, {}, ...)
