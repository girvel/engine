local safety = require "engine.tech.safety"
local action = {}

--- @class action
--- @field cost? table<string, number>
--- @field _is_available? fun(action, table): boolean
--- @field _act? fun(action, table): boolean
action.base = {
  is_available = function(self, entity)
    if self.cost
      and Fun.iter(self.cost):any(function(k, v) return (entity.resources[k] or 0) < v end)
    then
      return false
    end

    if self._is_available and not self:_is_available(entity) then
      return false
    end

    return true
  end,

  act = function(self, entity)
    if not safety.call(self.is_available, self, entity) then return false end
    if self._act then
      local result = safety.call(self._act, self, entity)
      assert(
        result == true or result == false,
        "action %s returned %s; actions must explicitly return true or false" % {
          Name.code(self), Inspect(result)
        }
      )
      if not result then return false end
    end
    for k, v in pairs(self.cost or {}) do
      entity.resources[k] = entity.resources[k] - v
    end
    return true
  end,
}

Ldump.mark(action, "const", ...)
return action
