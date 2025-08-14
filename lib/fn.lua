local module_mt = {}
--- Function extension module
local fn = setmetatable({}, module_mt)

module_mt.__call = function(_, ...)
  local args = {...}
  return function() return unpack(args) end
end

fn.identity = function(...) return ... end

--- @param f function
--- @return function
fn.curry = function(f, ...)
  local curried_args = {...}
  return function(...)
    local args = {unpack(curried_args)}
    for i = 1, select('#', ...) do
      table.insert(args, select(i, ...))
    end
    return f(unpack(args))
  end
end

return fn

