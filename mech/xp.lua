local xp = {}

--- @param level integer
--- @return integer
xp.get_proficiency_bonus = function(level)
  return 1 + math.ceil(level / 4)
end

xp.for_level = {[0] = 0, 0, 300, 900, 2700, 6500 }

xp.point_buy = {
  [8] = 0,
  [9] = 1,
  [10] = 2,
  [11] = 3,
  [12] = 4,
  [13] = 5,
  [14] = 7,
  [15] = 9,
}

Ldump.mark(xp, {}, ...)
return xp
