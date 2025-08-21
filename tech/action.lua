local action = {}

--- @class action
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

  run = function(self, entity)
    if not self:is_available(entity) then return false end
    for k, v in pairs(self.cost or {}) do
      entity.resources[k] = entity.resources[k] - v
    end
    return self:_run(entity)
  end,
}

Ldump.mark(action, "const", ...)
return action
