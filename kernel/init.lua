local init = {}

--- @class kernel
--- @field _save? string
--- @field _load? string
local methods = {}
local mt = {__index = methods}

--- @return kernel
init.new = function()
  return setmetatable({}, mt)
end

--- @param filepath string
methods.plan_save = function(self, filepath)
  self._save = filepath
end

--- @param filepath string
methods.plan_load = function(self, filepath)
  self._load = filepath
end

return init
