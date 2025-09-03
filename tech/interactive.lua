local interactive = {}

--- @class _interactive_methods
local methods = {}

--- @param interactor entity
--- @return entity?
interactive.get_for = function(interactor)
  for _, x in ipairs {
    State.grids.items[interactor.position],
    State.grids.tiles[interactor.position],
    State.grids.solids:slow_get(interactor.position + interactor.direction),
    State.grids.on_solids:slow_get(interactor.position + interactor.direction),
  } do
    if x and x.interact then
      return x
    end
  end
end

--- @param callback? fun(entity, entity)
interactive.mixin = function(callback)
  return Table.extend({
    on_interact = callback,
  }, methods)
end

--- @param self entity
--- @param other entity
methods.interact = function(self, other)
  local item = require("engine.tech.item")
  Log.debug("%s interacts with %s" % {Entity.codename(other), Entity.codename(self)})
  self.was_interacted_by = other
  item.set_cue(self, "highlight", false)
  if self.on_interact then
    self:on_interact(other)
  end
end

Ldump.mark(interactive, {
  mixin = {methods = "const"},
}, ...)
return interactive
