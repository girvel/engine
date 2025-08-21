local composite_map = {}

--- @class composite_map
--- @field _items table
--- @field _value any
local methods = {}
composite_map.mt = {__index = methods}

composite_map.new = function()
  return setmetatable({_items = {}}, composite_map.mt)
end

methods.set = function(self, value, head, ...)
  if head == nil then
    self._value = value
    return
  end

  if not self._items[head] then
    self._items[head] = {
      _items = {}
    }
  end

  self = self._items[head]
  methods.set(self, value, ...)
end

methods.get = function(self, head, ...)
  if head == nil then
    return self._value
  end

  if not self._items[head] then
    return nil
  end

  self = self._items[head]
  return methods.get(self, ...)
end

local iter

methods.iter = function(self)
  return coroutine.wrap(function() iter(self, {}) end)
end

iter = function(self, base)
  if self._value then
    coroutine.yield(base, self._value)
  end
  for k, v in pairs(self._items) do
    table.insert(base, k)
    iter(v, base)
    table.remove(base)
  end
end

return composite_map
