local action = require("engine.tech.action")


local raise_dead = {}

--- @class spells_raise_dead: action
--- @field target entity
local methods = {}
raise_dead.mt = {__index = methods}

--- @type spells_raise_dead|table
raise_dead.base = Table.extend({
  codename = "raise_dead",

  cost = {
    actions = 1,
    spell_slots_3 = 1,
  },
}, action.base)

--- @param target entity
--- @return spells_raise_dead
raise_dead.new = function(target)
  return setmetatable(Table.extend({
    target = target
  }, raise_dead.base), raise_dead.mt)
end

methods._is_available = function(self, entity)
  Log.traces(1)
  if not (State:exists(self.target) and self.target.body_flag) then return false end
  Log.traces(2)
  return true
end

methods._act = function(self, entity)
  State:remove(self.target)
  -- TODO remove reference to game code by extracting commonly used monsters & items
  local npcs = require("levels.main.palette.npcs")
  State:add(npcs.skeleton_heavy(), {
    position = State.grids.solids:find_free_position(self.target.position),
    grid_layer = "solids",
    faction = entity.faction
  })
  return true
end

Ldump.mark(raise_dead, {mt = "const"}, ...)
return raise_dead
