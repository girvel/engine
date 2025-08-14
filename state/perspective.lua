local view = require("engine.tech.view")


local perspective = {}

--- @class state_perspective
--- @field views table<string, view>
--- @field views_order string[]
--- @field offset_fs table<string, fun(vector, number): vector>
local methods = {}
local mt = {__index = methods}

local offsets = {}
local from_matrix

perspective.new = function()
  local views, views_order, offset_fs = from_matrix {
    {"grids", 4, offsets.camera},
  }

  return setmetatable({
    views = views,
    views_order = views_order,
    offset_fs = offset_fs,
  }, mt)
end

methods.update = function(self, dt)
  for _, key in ipairs(self.views_order) do
    self.views[key].offset = self.offset_fs[key](self.views[key].offset, dt)
  end
end

from_matrix = function(matrix)
  local views = {}
  local views_order = {}
  local views_offset_functions = {}

  for _, v in ipairs(matrix) do
    local name, scale, f = unpack(v)
    views[name] = view.new(Vector.zero, scale)
    table.insert(views_order, name)
    views_offset_functions[name] = f
  end

  return views, views_order, views_offset_functions
end

offsets.camera = function(prev, dt)
  return Vector.zero
end

Ldump.mark(perspective, {}, ...)
return perspective
