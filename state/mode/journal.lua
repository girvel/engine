local ui = require("engine.tech.ui")
local gui_elements = require("engine.state.mode.gui_elements")


local journal = {}

--- @class state_mode_journal
--- @field type "journal"
--- @field _game state_mode_game
local methods = {}
local mt = {__index = methods}

--- @param game state_mode_game
--- @return state_mode_journal
journal.new = function(game)
  return setmetatable({
    type = "journal",
    _game = game,
  }, mt)
end

methods.draw_grid = function(self, ...)
  self._game:draw_grid(...)
end

methods.draw_entity = function(self, ...)
  self._game:draw_entity(...)
end

local PADDING = 40
local DIMMED = Vector.hex("2A3E34")
local WHITE = Vector.hex("FFFFFF")

methods.draw_gui = function(self, dt)
  if ui.keyboard("escape") or ui.keyboard("j") then
    State.mode:close_journal()
  end

  local w = math.min(love.graphics.getWidth() - 4 * PADDING, 800)
  local h = love.graphics.getHeight() - 4 * PADDING

  ui.start_frame(
    (love.graphics.getWidth() - w) / 2 - PADDING,
    (love.graphics.getHeight() - h) / 2 - PADDING,
    w + 2 * PADDING,
    h + 2 * PADDING
  )
    ui.tile(gui_elements.window_bg)
  ui.finish_frame()

  ui.start_frame(
    (love.graphics.getWidth() - w) / 2,
    (love.graphics.getHeight() - h) / 2,
    w, h
  )
    ui.start_font(48)
    ui.start_alignment("center")
      ui.text("Журнал")
    ui.finish_alignment()
    ui.finish_font()

    for _, codename in ipairs(State.quests.order) do
      local quest = State.quests.items[codename]

      ui.start_font(36)
        ui.br()
        ui.start_line()
          love.graphics.setColor(DIMMED)
          ui.text("# ")
          love.graphics.setColor(WHITE)
          ui.text(quest.name)
        ui.finish_line()
      ui.finish_font()
      ui.br()

      for _, objective in ipairs(quest.objectives) do
        local prefix
        local needs_color_reset = true
        if objective.status == "done" then
          love.graphics.setColor(DIMMED)
          prefix = "+ "
        elseif objective.status == "failed" then
          love.graphics.setColor(DIMMED)
          prefix = "x "
        else
          prefix = "- "
          needs_color_reset = false
        end

        ui.text(prefix .. objective.text)

        if needs_color_reset then
          love.graphics.setColor(WHITE)
        end
      end
    end
  ui.finish_frame()
end

Ldump.mark(journal, {}, ...)
return journal
