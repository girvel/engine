return Tiny.processingSystem {
  codename = "drawing_under",
  base_callback = "draw",
  filter = function(_, entity)
    return entity.sprite and entity.position and
      Table.index_of(State.perspective.views_order, entity.view)
        < Table.index_of(State.perspective.views_order, "grids")
  end,

  process = function(_, entity, dt)
    State.mode:draw_entity(entity, dt)
  end,
}
