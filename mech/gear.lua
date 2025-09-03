local gear = {}

gear.helmet = {
  modify_armor = function(self, entity, armor)
    return armor + 1
  end,
}

Ldump.mark(gear, {}, ...)
return gear
