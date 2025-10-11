local ui = require("engine.tech.ui")
local level = require("engine.tech.level")

local BG = Vector.hex("191919")

return Tiny.sortedProcessingSystem {
  codename = "drawing",
  base_callback = "draw",
  filter = function(_, entity)
    return entity.sprite and entity.position and entity.layer
  end,

  compare = function(_, a, b)
    return Table.index_of(level.layers, a.layer) < Table.index_of(level.layers, b.layer)
  end,

  preProcess = function(_, dt)
    State.perspective:update(dt)
    local shader = State.shader
    if shader then
      love.graphics.setShader(shader.love_shader)
      if shader.update then
        shader:update(dt)
      end
    end

    love.graphics.clear(BG)
  end,

  process = function(_, entity, dt)
    State.mode:draw_entity(entity, dt)
  end,

  postProcess = function(_, dt)
    if State.shader then
      love.graphics.setShader()
    end
    ui.start()
    State.mode:draw_gui(dt)
    State.debug_overlay:draw(dt)
    ui.finish()
  end,
}
