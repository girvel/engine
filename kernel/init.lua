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

--- @return string[]
methods.list_saves = function(_)
  local result = {}
  for _, name in ipairs(love.filesystem.getDirectoryItems("saves")) do
    local full_path = "saves/" .. name
    if love.filesystem.getInfo(full_path).type ~= "file" or
      not name:ends_with(".ldump.gz")
    then
      goto continue
    end
    table.insert(result, name:sub(1, -10))

    ::continue::
  end
  return result
end

return init
