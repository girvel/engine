local sprite = require "engine.tech.sprite"
local item   = require "engine.tech.item"
local health = {}

-- NEXT
-- ---- @alias healthy {hp: integer, get_max_hp: fun(self): integer, immortal: true?}
-- --- @alias healthy any
-- 
-- --- Restores `amount` of `target`'s health with FX
-- --- @param target healthy
-- --- @param amount integer
-- --- @return nil
-- health.heal = function(target, amount)
--   local value = target.hp + amount
--   if target.get_max_hp then
--     value = math.min(target:get_max_hp(), value)
--   end
--   health.set_hp(target, value)
--   if target.position then
--     State:add(gui.floating_damage("+" .. amount, target.position, Colors.light_green))
--   end
-- end

local floating_damage

--- Inflict fixed damage; handles hp, death and FX
--- @param target table
--- @param amount number
--- @param is_critical? boolean whether to display damage as critical
--- @return nil
health.damage = function(target, amount, is_critical)
  -- if target.get_effect then
  --   amount = target:get_effect("modify_incoming_damage", amount)
  -- end
  -- NEXT (modifiers)

  amount = math.max(0, amount)
  Log.debug("%s damage to %s" % {amount, Entity.codename(target)})

  if is_critical then
    State:add(floating_damage(amount .. "!", target.position))
  else
    State:add(floating_damage(amount, target.position))
  end

  health.set_hp(target, target.hp - amount)
  if target.hp <= 0 then
    if target.on_death then
      target:on_death()
    end

    if target.inventory then
      for _, slot in ipairs(item.DROPPING_SLOTS) do
        local this_item = target.inventory[slot]
        if this_item then
          item.drop(target, slot)
        end
      end
    end

    State:remove(target)
    if not target.boring_flag then
      Log.info(Entity.codename(target) .. " is killed")
    end
  end
end

--- Set HP, update blood cue
--- @param target table
--- @param value integer
--- @return nil
health.set_hp = function(target, value)
  target.hp = value

  -- NEXT (when cues)

  -- if target.get_max_hp then
  --   cue.set(target, "blood", target.hp <= target:get_max_hp() / 2)
  -- end
end

floating_damage = function(number, grid_position)
  local a = math.floor(State.level.cell_size * .25)
  local b = math.floor(State.level.cell_size * .75)
  return {
    boring_flag = true,
    codename = "floating_damage",
    position = grid_position * State.level.cell_size
      + V(math.random(a, b), math.random(a, b)),
    view = "grids_fx",
    drift = V(0, -4),
    sprite = sprite.text(tostring(number), 16, Vector.hex("e7573e")),
    life_time = 3,
  }
end

Ldump.mark(health, {}, ...)
return health
