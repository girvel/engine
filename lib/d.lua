local module_mt = {}
--- @overload fun(integer): d
local d = setmetatable({}, module_mt)

----------------------------------------------------------------------------------------------------
-- [SECTION] Die
----------------------------------------------------------------------------------------------------

--- @class die
--- @field sides_n integer
--- @field advantage boolean
--- @field reroll integer[]
local die_methods = {}
d.die_mt = {__index = die_methods}

d.die_new = function(sides_n)
  return setmetatable({
    sides_n = sides_n,
    advantage = false,
    reroll = {},
  }, d.die_mt)
end

d.die_mt.__tostring = function(self)
  return "d%s%s%s" % {
    self.sides_n,
    self.advantage and "↑" or "",
    #self.reroll > 0 and ("🗘(%s)" % table.concat(self.reroll, ",")) or ""
  }
end

--- @return integer
die_methods.roll = function(self)
  local result = math.random(self.sides_n)
  if self.advantage then
    result = math.max(result, math.random(self.sides_n))
  end
  if Table.contains(self.reroll, result) then
    result = math.random(self.sides_n)
  end
  return result
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Dice
----------------------------------------------------------------------------------------------------

--- @class d
--- @field dice die[]
--- @field bonus integer
--- @operator add(d): d
--- @operator sub(integer): d
--- @operator mul(integer): d
local methods = {}
d.mt = {__index = methods}

--- @param dice die[]
--- @param bonus integer
d.new = function(dice, bonus)
  return setmetatable({
    dice = dice,
    bonus = bonus,
  }, d.mt)
end

module_mt.__call = function(_, sides_n)
  return d.new({d.die_new(sides_n)}, 0)
end

d.mt.__add = function(self, other)
  if type(other) == "number" then
    return d.new(Table.deep_copy(self.dice), self.bonus + other)
  end

  if type(other) == "table" then
    return d.new(
      Table.concat(Table.deep_copy(self.dice), other.dice),
      self.bonus + other.bonus
    )
  end

  error("Trying to add %s to a dice roll" % type(other))
end

d.mt.__sub = function(self, other)
  if type(other) == "number" then
    return d.new(Table.deep_copy(self.dice), self.bonus - other)
  end

  error("Trying to subtract %s to a dice roll" % type(other))
end

d.mt.__mul = function(self, other)
  assert(type(other) == "number")
  return d.new(
    Fun.iter(self.dice)
      :cycle()
      :take_n(#self.dice * other)
      :map(function(d) return Table.deep_copy(d) end)
      :totable(),
    self.bonus * other
  )
end

d.mt.__tostring = function(self)
  local dice = table.concat(
    Fun.iter(self.dice)
      :map(tostring)
      :totable(),
    " + "
  )
  local bonus = ""
  if self.bonus ~= 0 then
    bonus = "%+i" % self.bonus
    bonus = " " .. bonus:sub(1, 1) .. " " .. bonus:sub(2)
  end
  return dice .. bonus
end

--- @return integer
methods.roll = function(self)
  local rolls = Fun.iter(self.dice)
    :map(function(d) return d:roll() end)
    :totable()
  local result = Fun.iter(rolls):sum() + self.bonus

  Log.debug(
    table.concat(
      Fun.zip(self.dice, rolls)
        :map(function(d, r)
          return "%s (%s)" % {r, tostring(d)}
        end)
        :totable(),
      " + "
    ) .. " + " .. self.bonus .. " = " .. result
  )

  return result
end

--- @return integer
methods.max = function(self)
  return Fun.iter(self.dice)
    :map(function(d) return d.sides_n end)
    :sum() + self.bonus
end

--- @return integer
methods.min = function(self)
  return #self.dice + self.bonus
end

--- @param modification die
--- @return d
methods.extended = function(self, modification)
  return d.new(
    Fun.iter(self.dice)
      :map(function(x)
        return Table.extend(Table.deep_copy(x), modification)
      end)
      :totable(),
    self.bonus
  )
end

--- @generic T: d
--- @param self T
--- @return T
methods.copy = function(self)
  --- @cast self d
  return d.new(Table.deep_copy(self.dice), self.bonus)
end

return d
