return Tiny.processingSystem {
  codename = "acting",
  base_callback = "update",
  filter = Tiny.requireAll("ai"),

  process = function(self, entity, dt)
    if entity.ai.run then
      entity.ai.run(entity, dt)
    end
  end,
}
