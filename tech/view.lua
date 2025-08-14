local view = {}

--- Coordinate system: scale + offset
--- @class view
--- @field offset vector
--- @field scale vector
local methods = {}
view.mt = {__index = methods}

view.new = function(offset, scale)
  return setmetatable({
    offset = offset,
    scale = scale,
  }, view.mt)
end

methods.apply = function(self, v)
  return self.offset + v * self.scale
end

methods.apply_scalar = function(self, x, y)
  return
    self.offset.x + x * self.scale,
    self.offset.y + y * self.scale
end

methods.inverse = function(self, v)
  return (v - self.offset) / self.scale
end

Ldump.mark(view, {}, ...)
return view
