local health = require "engine.mech.health"


local attacking = {}

--- Attacks with given attack/damage rolls
--- @param target entity attacked entity
--- @param attack_roll table
attacking.attack = function(target, attack_roll, damage_roll)
  local attack = attack_roll:roll()
  local is_nat = attack == attack_roll:max()
  local is_nat_miss = attack == attack_roll:min()
  local ac = target.get_armor and target:get_armor() or target.armor or 0

  Log.info("%s is attacked; attack roll: %s, armor: %s" % {Entity.name(target), attack, ac})

  if is_nat_miss then
    State:add(health.floating_damage("!", target.position))
    return false
  end

  if attack < ac and not is_nat then
    State:add(health.floating_damage("-", target.position))
    return false
  end

  local is_critical = is_nat and attack >= ac
  if is_critical then
    damage_roll = damage_roll + D.roll(damage_roll.dice, 0)
  end

  health.damage(target, damage_roll:roll(), is_critical)
  return true
end

attacking.attack_save = function(target, ability, save_dc, damage_roll)
  local success = abilities.saving_throw(target, ability, save_dc)

  if success then
    State:add(gui.floating_damage("-", target.position))
    return false
  end

  health.damage(target, damage_roll:roll())
  return true
end

Ldump.mark(attacking, {}, ...)
return attacking
