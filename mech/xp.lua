local xp = {}

--- @param level integer
--- @return integer
xp.get_proficiency_bonus = function(level)
  return 1 + math.ceil(level / 4)
end

Ldump.mark(xp, {}, ...)
return xp
