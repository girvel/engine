local ui = require("engine.tech.ui")
local tcod = require("engine.tech.tcod")
local tk = require("engine.state.mode.tk")


local start_menu = {}

--- @class state_mode_start_menu
--- @field type "start_menu"
local methods = {}
local mt = {__index = methods}

start_menu.new = function()
  return setmetatable({
    type = "start_menu",
  }, mt)
end

local display_tcod_error
local is_displaying_tcod_error = not tcod.ok

methods.draw_gui = function()
  if is_displaying_tcod_error then return display_tcod_error() end

  ui.start_font(48)
  ui.start_frame(200, 200, 500, 500)
    local choice = ui.choice({
      "Новая игра",
      "Загрузить игру",
      "Выход",
    })

    if choice then
      ui.reset_selection()
    end

    if choice == 1 then
      State.mode:start_game()
    elseif choice == 2 then
      State.mode:open_load_menu()
    elseif choice == 3 then
      Log.info("Exiting from the main menu")
      love.event.quit()
    end
  ui.finish_frame()
  ui.finish_font()
end

display_tcod_error = function()
  tk.start_window("center", "center", 470, 160)
  ui.start_font(20)
  ui.start_alignment("center")
    ui.text("Невозможно загрузить библиотеку libtcod, поля зрения и поиск путей не будут работать")
    ui.br()
    ui.text("Возможно, путь к папке с игрой содержит не-английские символы. Попробуйте переместить её в другое место.")
    ui.br()
    if ui.choice({"ОК"}) then
      is_displaying_tcod_error = false
    end
  ui.finish_alignment()
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(start_menu, {}, ...)
return start_menu
