local feats = {}

feats.savage_attacker = {
  name = "Неистовый атакующий",
  codename = "savage_attacker",
  description = "Атаки наносят больше урона",

  modify_damage_roll = function(self, entity, roll, slot)
    if entity.inventory[slot] then
      return roll:set("advantage")
    end
    return roll
  end,
}

-- TODO bonus action attack
-- TODO passive
feats.great_weapon_master = {
  name = "Мастер большого оружия",
  codename = "great_weapon_master",
  description = "Шанс попадания двуручным оружием меньше на 25%, урон выше на 10",

  modify_attack_roll = function(self, entity, roll, slot)
    local item = entity.inventory[slot]
    if item and item.tags.heavy then
      return roll - 5
    end
    return roll
  end,

  modify_damage_roll = function(self, entity, roll, slot)
    local item = entity.inventory[slot]
    if item and item.tags.heavy then
      return roll + 10
    end
    return roll
  end,
}

Ldump.mark(feats, "const", ...)
return feats
