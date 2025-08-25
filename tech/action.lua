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
    if not self:is_available(entity) then return false end
    if self._act then
      local result = self:_act(entity)
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
