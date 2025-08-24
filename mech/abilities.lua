local abilities = {}

--- @alias ability "str"|"dex"|"con"|"int"|"wis"|"cha"
--- @alias abilities table<ability, integer>

abilities.new = function(str, dex, con, int, wis, cha)
  return {
    str = str,
    dex = dex,
    con = con,
    int = int,
    wis = wis,
    cha = cha,
  }
end

abilities.set = Table.set {
  "str", "dex", "con",
  "int", "wis", "cha",
} --[[@as table<ability, true>]]

--- @enum (key) skill
abilities.skill_bases = {
  athletics = "str",
  sleight_of_hand = "dex",
  arcana = "int",
  history = "int",
  investigation = "int",
  nature = "int",
  religion = "int",
  insight = "wis",
  medicine = "wis",
  perception = "wis",
  intimidation = "cha",
  persuasion = "cha",
}

--- @param ability_score integer
--- @return integer
abilities.get_modifier = function(ability_score)
  return math.floor((ability_score - 10) / 2)
end

Ldump.mark(abilities, {}, ...)
return abilities
