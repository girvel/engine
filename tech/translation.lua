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
    money = "Деньги",
  },
}

Ldump.mark(translation, "const", ...)
return translation
