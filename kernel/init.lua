local init = {}

--- @class kernel middleware between fallen engine and LOVE
--- @field _save? string
--- @field _load? string
--- @field _specific_key_rates table<love.KeyConstant, number>
local methods = {}
local mt = {__index = methods}

--- @return kernel
init.new = function()
  return setmetatable({
    _specific_key_rates = {},
  }, mt)
end

--- @param filepath string
methods.plan_save = function(self, filepath)
  self._save = "saves/" .. filepath .. ".ldump.gz"
end

--- @param filepath string
methods.plan_load = function(self, filepath)
  self._load = "saves/" .. filepath .. ".ldump.gz"
end

--- @return string[]
methods.list_saves = function(_)
  local result = {}
  local dates = {}

  for _, name in ipairs(love.filesystem.getDirectoryItems("saves")) do
    local full_path = "saves/" .. name
    if love.filesystem.getInfo(full_path).type ~= "file" or
      not name:ends_with(".ldump.gz")
    then
      goto continue
    end

    name = name:sub(1, -10)
    table.insert(result, name)
    dates[name] = love.filesystem.getInfo(full_path).modtime

    ::continue::
  end

  table.sort(result, function(a, b) return dates[a] > dates[b] end)
  return result
end

--- @param key love.KeyConstant
--- @param value number
methods.set_key_rate = function(self, key, value)
  self._specific_key_rates[key] = value
end

--- @param key love.KeyConstant
--- @return number
methods.get_key_rate = function(self, key)
  return self._specific_key_rates[key]
end

return init
