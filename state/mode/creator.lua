local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")


local creator = {}

--- @class state_mode_creator
--- @field type "creator"
--- @field _prev state_mode_game
local methods = {}
creator.mt = {__index = methods}

--- @param prev state_mode_game
--- @return state_mode_creator
creator.new = function(prev)
  return setmetatable({
    type = "creator",
    _prev = prev,
  }, creator.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  if ui.keyboard("escape") or ui.keyboard("c") then
    State.mode:close_menu()
  end

  tk.start_window("center", "center", "read_max", "max")
    ui.h1("Персонаж")
  tk.finish_window()
end

Ldump.mark(creator, {mt = "const"}, ...)
return creator
