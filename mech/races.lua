local races = {}

races.human = {
  codename = "human",
  name = "Разносторонний человек",
}

races.variant_human = {
  codename = "variant_human",
  name = "Альтернативный человек",
}

races.custom_lineage = {
  codename = "custom_lineage",
  name = "Необычное происхождение",
}

Ldump.mark(races, {}, ...)
return races
