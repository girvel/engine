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

--- @param ... promise
--- @return promise
promise.all = function(...)
  local result = promise.new()
  local count = select("#", ...)
  for i = 1, count do
    local item = select(i, ...)  --[[@as promise]]
    if i ~= count or getmetatable(item) == promise.mt then
      item:next(function()
        count = count - 1
        if count == 0 then
          result:resolve()
        end
      end)
    else
      count = count - 1
    end
  end
  return result
end

--- @param callback function
--- @return promise
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
promise_methods.wait = function(self)
  while not self.is_resolved do
    coroutine.yield()
  end
end

return promise
