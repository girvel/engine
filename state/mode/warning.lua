local ui = require("engine.tech.ui")
local tk = require("engine.state.mode.tk")


local warning = {}

--- @class state_mode_warning
--- @field type "warning"
--- @field message string
--- @field _prev table
local methods = {}
warning.mt = {__index = methods}

--- @return state_mode_warning
warning.new = function(prev, message)
  ui.handle_selection_reset()
  return setmetatable({
    type = "warning",
    message = message,
    _prev = prev,
  }, warning.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self)
  tk.start_window("center", "center", 470, 160)
  ui.start_font(28)
  ui.start_alignment("center")
    ui.text(self.message)
    ui.br()

    local n = ui.choice({"OK  "})

    if n == 1 or ui.keyboard("escape") then
      State.mode:close_menu()
    end
  ui.finish_alignment()
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(warning, {mt = "const"}, ...)
return warning
