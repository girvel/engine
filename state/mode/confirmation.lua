local ui = require("engine.tech.ui")
local tk = require("engine.state.mode.tk")


local confirmation = {}

--- @class state_mode_confirmation
--- @field type "confirmation"
--- @field message string
--- @field f fun()
--- @field _prev table
local methods = {}
confirmation.mt = {__index = methods}

--- @return state_mode_confirmation
confirmation.new = function(prev, message, f)
  ui.handle_selection_reset()
  return setmetatable({
    type = "confirmation",
    message = message,
    f = f,
    _prev = prev,
  }, confirmation.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self)
  tk.start_window("center", "center", 470, 100)
  ui.start_font(28)
  ui.start_alignment("center")
    ui.text(self.message)
    ui.br()

    local n = ui.choice({"OK  ", "Отмена  "})

    if n == 1 then
      State.mode:close_menu()
      self.f()
    elseif n == 2 or ui.keyboard("escape") then
      State.mode:close_menu()
    end
  ui.finish_alignment()
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(confirmation, {mt = "const"}, ...)
return confirmation
