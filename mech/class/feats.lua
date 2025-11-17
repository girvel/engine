local feats = {}

feats.savage_attacker = {
  codename = "savage_attacker",

  modify_damage_roll = function(self, entity, roll, slot)
    if entity.inventory[slot] then
      return roll:set("advantage")
    end
    return roll
  end,
}

Ldump.mark(feats, "const", ...)
return feats
