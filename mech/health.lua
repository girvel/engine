local sprite = require "engine.tech.sprite"
local item   = require "engine.tech.item"


local health = {}

health.COLOR_DAMAGE = Vector.hex("e7573e")
health.COLOR_HEALING = Vector.hex("c3e06c")

--- Restores `amount` of `target`'s health with FX
--- @param target entity
--- @param amount integer
--- @return nil
health.heal = function(target, amount)
  local value = target.hp + amount
  if target.get_max_hp then
    value = math.min(target:get_max_hp(), value)
  end
  health.set_hp(target, value)
  if target.position then
    State:add(health.floater("+" .. amount, target.position, health.COLOR_HEALING))
  end
end

--- Inflict fixed damage; handles hp, death and FX
--- @param target entity
--- @param amount number
--- @param is_critical? boolean whether to display damage as critical
--- @return nil
health.damage = function(target, amount, is_critical)
  amount = math.max(0, amount)
  Log.debug("%s damage to %s", amount, Name.code(target))

  local repr = tostring(amount)
  if is_critical then
    repr = repr .. "!"
  end

  State:add(health.floater(repr, target.position, health.COLOR_DAMAGE))

  local before = target.hp
  health.set_hp(target, before - amount)
  if target.hp <= 0 then
    if target.on_death then
      target:on_death()
    else
      health.add_blood(target.position)
    end

    if target.player_flag then
      State.mode:player_has_died()
      return
    end

    if target.essential_flag then
      State.runner:run_task(function()
        target:animate("lying")
        coroutine.yield()
        target:animation_set_paused(true)
      end, "essential_down")

      if State:in_combat(target) then
        State.combat:remove(target)
      end

      return
    end

    if target.inventory then
      local to_drop = {}
      for _, slot in ipairs(item.DROPPING_SLOTS) do
        local this_item = target.inventory[slot]
        if this_item and not this_item.no_drop_flag then
          table.insert(to_drop, slot)
        end
      end
      item.drop(target, unpack(to_drop))
    end

    State:remove(target)
    if not target.boring_flag then
      Log.info(Name.code(target) .. " is killed")
    end
  else
    local half = target:get_max_hp() / 2
    if before > half and target.hp <= half then
      health.add_blood(target.position)
    end
  end
end

--- Set HP, update blood cue, handle modifiers
--- @param target entity
--- @param value integer
--- @return nil
health.set_hp = function(target, value)
  target.hp = target:modify("hp", value)

  if target.get_max_hp and not target.no_blood_flag then
    item.set_cue(target, "blood", target.hp <= target:get_max_hp() / 2)
  end
end

--- Attacks with given attack/damage rolls
--- @param source entity attacking entity
--- @param target entity attacked entity
--- @param attack_roll table
--- @return boolean did_hit true if attack landed
health.attack = function(source, target, attack_roll, damage_roll)
  local attack = attack_roll:roll()
  local is_nat = attack == attack_roll:max()
  local is_nat_miss = attack == attack_roll:min()
  local ac = target.get_armor and target:get_armor() or target.armor or 0

  Log.info("%s attacks %s; attack roll: %s, armor: %s", source, target, attack, ac)

  if is_nat_miss then
    State:add(health.floater("!", target.position, health.COLOR_DAMAGE))
    return false
  end

  if attack < ac and not is_nat then
    State:add(health.floater("-", target.position, health.COLOR_DAMAGE))
    return false
  end

  local is_critical = is_nat and attack >= ac
  if is_critical then
    damage_roll = damage_roll + D.new(damage_roll.dice, 0)
  end

  local damage_amount = source:modify("outgoing_damage", damage_roll:roll(), target, is_critical)
  health.damage(target, damage_amount, is_critical)
  return true
end

-- health.attack_save = function(target, ability, save_dc, damage_roll)
--   local success = abilities.saving_throw(target, ability, save_dc)
-- 
--   if success then
--     State:add(gui.floating_damage("-", target.position))
--     return false
--   end
-- 
--   health.damage(target, damage_roll:roll())
--   return true
-- end

--- Floating text for damage & such
--- @param text string|number
--- @param grid_position vector
--- @param color vector
health.floater = function(text, grid_position, color)
  return {
    boring_flag = true,
    codename = "floating_damage",
    position = grid_position
      + V(math.random() * .5 + .25, math.random() * .5 + .25),
    drift = V(0, -.25),
    sprite = sprite.text(tostring(text), 16, color),
    life_time = 3,
    layer = "fx_over",
  }
end

health.add_blood = function(position)
  local final_position
  for d in Iteration.rhombus(2) do
    local p = d:add_mut(position)
    if not State.grids.tiles:can_fit(p) then goto continue end

    local on_tile = State.grids.on_tiles[p]
    if on_tile and on_tile.codename == "blood" then goto continue end

    local solid = State.grids.solids[p]
    if solid and not solid.transparent_flag then goto continue end

    final_position = p
    do break end

    ::continue::
  end

  if not final_position then return end

  local atlas = love.image.newImageData("engine/assets/sprites/blood.png")

  return State:add {
    codename = "blood",
    boring_flag = true,

    position = final_position,
    grid_layer = "on_tiles",

    sprite = sprite.image(sprite.utility.select(atlas, math.random(1, 2))),
  }
end

Ldump.mark(health, {}, ...)
return health
