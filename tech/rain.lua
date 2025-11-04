local animated = require("engine.tech.animated")
local api = require("engine.tech.api")
local rain = {}

--- @alias rain rain_strict|table
--- @class rain_strict: entity_strict
--- @field ai rain_ai
--- @field rain_density number
--- @field rain_speed number

--- @alias rain_ai rain_ai_strict|table
--- @class rain_ai_strict: ai_strict
--- @field _particles particle[]
--- @field _player_position vector
local ai_methods = {}
rain.ai_mt = {__index = ai_methods}

--- @class particle
--- @field position vector in pixels (before scaling)
--- @field target_cell vector
--- @field life_time number
--- @field is_visible boolean

--- @param density number
--- @param speed number
--- @return rain
rain.new = function(density, speed)
  return {
    non_positional_ai_flag = true,
    codename = "rain_emitter",
    position = Vector.one,
    layer = "weather",
    sprite = {
      type = "image",
      image = love.graphics.newCanvas(unpack(State.level.grid_size * Constants.cell_size)),
      anchors = {},
      color = Vector.white,
    },

    rain_density = density,
    rain_speed = speed,

    ai = setmetatable({
      _particles = {},
      _player_position = nil,
    }, rain.ai_mt),
  }
end

local BUFFER_K = 2
local DIRECTION = V(1, 1):normalized_mut()
local IMAGE = love.graphics.newImage("assets/sprites/standalone/rain_particle.png")

--- @param entity rain
ai_methods.observe = function(self, entity, dt)
  local start, finish do
    local original_start = State.perspective.vision_start * Constants.cell_size
    local original_finish = (State.perspective.vision_end + Vector.one) * Constants.cell_size

    local d = (original_finish - original_start)
    start = original_finish - d * BUFFER_K
    finish = original_start + d * BUFFER_K
  end

  local d, cells_n do
    local w, h = unpack(finish - start)
    d = math.max(w, h)
    cells_n = w * h / Constants.cell_size^2
  end

  local life_time = d / Constants.cell_size / entity.rain_speed
  local velocity = DIRECTION * entity.rain_speed * Constants.cell_size

  local did_vision_change do
    did_vision_change = self._player_position ~= State.player.position
    self._player_position = State.player.position
  end

  while State.period:absolute(life_time / entity.rain_density / cells_n, self, "emit_rain") do
    local target = Vector.use(Random.float, start, finish)
    local target_cell = target / Constants.cell_size

    table.insert(self._particles, {
      position = target - DIRECTION * d,
      target_cell = target_cell,
      life_time = life_time,
      is_visible = api.is_visible(target_cell),
    })
  end

  love.graphics.setCanvas(entity.sprite.image)
    love.graphics.clear(Vector.transparent)

    for _, p in ipairs(self._particles) do
      p.position = p.position + velocity * dt
      p.life_time = p.life_time - dt
      if did_vision_change then
        p.is_visible = api.is_visible(p.target_cell)
      end
      if p.is_visible then
        love.graphics.draw(IMAGE, unpack(p.position))
      end
    end

    for i = #self._particles, 1, -1 do
      local p = self._particles[i]
      if p.life_time <= 0 then
        Table.remove_breaking_at(self._particles, i)
        if p.is_visible then
          animated.add_fx("assets/sprites/animations/rain_impact", p.position / Constants.cell_size, "weather")
        end
      end
    end
  love.graphics.setCanvas()
end

Ldump.mark(rain, {mt = "const"}, ...)
return rain
