local translation = {
  resources = {
    bonus_actions = "бонусные действия",
    movement = "движение",
    reactions = "реакции",
    actions = "действия",
    second_wind = "второе дыхание",
    action_surge = "всплеск действий",
    hit_dice = "перевязать раны",
    fighting_spirit = "боевой дух",
  },
  bag = {
    money = "Ценности",
  },

  abilities = {
    str = "сила",
    dex = "ловкость",
    con = "телосложение",
    int = "интеллект",
    wis = "мудрость",
    cha = "харизма",
  },

  skills = {
    athletics = "атлетика",
    acrobatics = "акробатика",
    sleight_of_hand = "ловкость рук",
    stealth = "скрытность",
    arcana = "магия",
    history = "история",
    investigation = "расследование",
    nature = "природа",
    religion = "религия",
    animal_handling = "уход за животными",
    insight = "проницательность",
    medicine = "медицина",
    perception = "внимание",
    deception = "обман",
    intimidation = "запугивание",
    performance = "выступление",
    persuasion = "убеждение",
    survival = "выживание",
  },

  items = {
    tags = {
      two_handed = "двуручное",
      light = "лёгкое",
      finnesse = "фехтовальное",
      heavy = "тяжёлое",
      versatile = "полуторное",
    },
  },

  feats = {
    savage_attacker = "Неистовый атакующий",
    great_weapon_master = "Мастер двуручного оружия",
  },
}

Ldump.mark(translation, "const", ...)
return translation
