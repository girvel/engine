local creature = {}

creature.new = function()
  return {
    resources = {
      movement = 6,
    },
  }
end

Ldump.mark(creature, {}, ...)
return creature
