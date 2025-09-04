local promise = {}

--- @class promise
--- @field is_resolved boolean
--- @field queue function[]
local promise_methods = {}
promise.mt = {__index = promise_methods}

--- @return promise
promise.new = function()
  return setmetatable({
    is_resolved = false,
    queue = {},
  }, promise.mt)
end

--- @param callback function
promise_methods.next = function(self, callback)
  table.insert(self.queue, callback)
  return self
end

promise_methods.resolve = function(self, ...)
  self.is_resolved = true
  local args = {...}
  for _, callback in ipairs(self.queue) do
    args = {callback(unpack(args))}
  end
  return unpack(args)
end

--- @async
promise_methods.await = function(self)
  while not self.is_resolved do
    coroutine.yield()
  end
end

return promise
