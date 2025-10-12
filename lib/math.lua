--- Math extension module
---
--- Contains additional math functions
local mathx = {}

--- Returns 1 if x is positive, -1 if negative, 0 if 0
--- @param x number
--- @return number
mathx.sign = function(x)
  if x == 0 then return 0 end
  if x > 0 then return 1 end
  return -1
end

--- @param ... number
--- @return number
mathx.median = function(...)
  local t = {...}
  table.sort(t)
  return t[math.ceil(#t / 2)]
end

--- @param t number[]
--- @return number
mathx.average = function(t)
  return Fun.iter(t):sum() / #t
end

--- Loops a between 1 and b the same way a % b loops a in between 0 and b - 1 in 0-based indexing
--- @param a number
--- @param b number
--- @return number
mathx.loopmod = function(a, b)
  return (a - 1) % b + 1
end

--- @param start
--- @param p1 vector
--- @param p2 vector
--- @return boolean
local probe = function(start, p1, p2)
  local xr, yr = unpack(start)
  local x1, y1 = unpack(p1)
  local x2, y2 = unpack(p2)

  if not ((y1 <= yr and y2 > yr) or (y2 <= yr and y1 > yr)) then
    return false
  end

  if y1 == y2 then return yr == y1 and xr <= math.max(x1, x2) end

  local x_intersect
  if x1 == x2 then
    x_intersect = x1
  else
    local k = (x2 - x1) / (y2 - y1)
    x_intersect = (yr - y1) * k + x1
  end

  return x_intersect > xr
end

--- @param p vector
--- @param vertices vector[]
--- @return boolean
mathx.inside_polygon = function(p, vertices)
  local count = 0
  for i = 1, #vertices do
    if probe(p, vertices[i], vertices[mathx.loopmod(i + 1, #vertices)]) then
      count = count + 1
    end
  end

  return count % 2 == 1
end

return mathx
