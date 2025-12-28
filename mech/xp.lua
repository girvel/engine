local xp = {}

--- @param level integer
--- @return integer
xp.get_proficiency_bonus = function(level)
  return 1 + math.ceil(level / 4)
end

xp.for_level = {[0] = -1, 0, 300, 900, 2700, 6500 }

Ldump.mark(xp, {}, ...)
return xp
