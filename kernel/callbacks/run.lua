local saves = require "engine.kernel.saves"


local handle_event = function(event, ...)
  if not Kernel._is_active then return end
  State._world:update(function(_, system) return system.base_callback == event end, ...)
end

return function()
  love.load(love.arg.parseGameArguments(arg), arg)

  love.timer.step()
  local dt = 0
  local KEY_REPETITION_DELAY = .3
  local serialization_coroutine

  Kernel.start_time = love.timer.getTime()
  return function()
    if Kernel._save then
      serialization_coroutine = coroutine.create(function()
        saves.write(State, Kernel._save)
      end)
      Kernel._save = nil
    end

    if serialization_coroutine then
      love.event.pump()
      for name in love.event.poll() do
        if name == "quit" then
          return 0
        end
      end

      love.graphics.origin()
      love.graphics.clear()
        love.graphics.print("Saving" .. "." * math.floor((love.timer.getTime() * 4) % 4), 100, 100)
      love.graphics.present()

      coroutine.resume(serialization_coroutine)
      love.timer.step()
      if coroutine.status(serialization_coroutine) == "dead" then
        serialization_coroutine = nil
      else
        return
      end
    end

    if Kernel._load then
      local t = love.timer.getTime()
        State = saves.read(Kernel._load)  --[[@as state]]
        if State.mode._mode.type == "escape_menu" then
          State.mode:close_menu()
        end
        Kernel._load = nil
        State.runner:handle_loading()
      Kernel.cpu_time = math.max(Kernel.cpu_time - (love.timer.getTime() - t))
    end

    Kernel._is_active = love.window.isVisible()
      and love.window.hasFocus()

    love.event.pump()
    for name, a,b,c,d,e,f in love.event.poll() do
      if name == "quit" then
        if not love.quit or not love.quit() then
          return a or 0
        end
      elseif name == "keypressed" then
        Kernel._delays[b] = KEY_REPETITION_DELAY
      elseif name == "keyreleased" then
        Kernel._delays[b] = nil
      end
      handle_event(name, a,b,c,d,e,f)
    end

    dt = love.timer.step()
    Kernel.cpu_time = Kernel.cpu_time + dt
    Kernel.frame_n = Kernel.frame_n + 1

    for k, v in pairs(Kernel._delays) do
      Kernel._delays[k] = math.max(0, v - dt)
      if Kernel._delays[k] == 0 then
        handle_event("keypressed", nil, k, true)
        Kernel._delays[k] = 1 / Kernel:get_key_rate(k)
      end
    end

    handle_event("update", dt)

    if Kernel._is_active then
      love.graphics.origin()
      love.graphics.clear(love.graphics.getBackgroundColor())
    end

    handle_event("draw", dt)

    do
      local t = love.timer.getTime()
        love.graphics.present()
      Kernel.cpu_time = math.max(0, Kernel.cpu_time - (love.timer.getTime() - t))
    end
  end
end
