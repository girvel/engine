local init = {}

--- @class kernel middleware between fallen engine and LOVE
--- @field _save? string
--- @field _load? string
--- @field _specific_key_rates table<love.KeyConstant, number>
--- @field _delays table<love.KeyConstant, number>
--- @field _total_frames integer
--- @field _total_time number
local methods = {}
local mt = {__index = methods}

--- @return kernel
init.new = function()
  return setmetatable({
    _specific_key_rates = {},
    _delays = {},
    _total_frames = 0,
    _total_time = 0,
  }, mt)
end

--- @param name string
methods.plan_save = function(self, name)
  self._save = "saves/" .. name .. ".ldump.gz"
end

--- @param name string
methods.plan_load = function(self, name)
  self._load = "saves/" .. name .. ".ldump.gz"
end

--- @param key love.KeyConstant
--- @param value number
methods.set_key_rate = function(self, key, value)
  self._specific_key_rates[key] = value
end

local DEFAULT_KEY_RATE = 5

--- @param key love.KeyConstant
--- @return number
methods.get_key_rate = function(self, key)
  return self._specific_key_rates[key] or DEFAULT_KEY_RATE
end

methods.report = function(self)
  if State.args.profiler then
    Log.info(Profile.report(100))
  end

  local line_report = Lp.report()
  if #line_report > 0 then
    Log.info(line_report)
  end

  Log.info("Average FPS is %.2f", self._total_frames / self._total_time)
  Log.info("Saved log to %s%s", love.filesystem.getRealDirectory(Log.outfile), Log.outfile)
  Log.report()
end

return init
