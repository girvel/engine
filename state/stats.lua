local stats = {}

--- @class state_stats
--- @field active_ais string[]
local methods = {}
stats.mt = {__index = methods}

--- @return state_stats
stats.new = function()
  return setmetatable({
    active_ais = {},
  }, stats.mt)
end

Ldump.mark(stats, {mt = "const"}, ...)
return stats
