local ui = require("engine.tech.ui")
local tk = require("engine.state.mode.tk")


local appearance_editor = {}

--- @class state_mode_appearance_editor
local methods = {}
appearance_editor.mt = {__index = methods}

--- @return state_mode_appearance_editor
appearance_editor.new = function(prev)
  return setmetatable({
    type = "appearance_editor",
    _prev = prev,
  }, appearance_editor.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  tk.start_window("center", "center", 780, 700)
    ui.text("Hello, world!")
  tk.finish_window()
end

Ldump.mark(appearance_editor, {mt = "const"}, ...)
return appearance_editor
