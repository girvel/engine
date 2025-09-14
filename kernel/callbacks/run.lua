local saves = require "engine.kernel.saves"


return function()
	love.load(love.arg.parseGameArguments(arg), arg)

	love.timer.step()
	local dt = 0
  local KEY_REPETITION_DELAY = .3
	return function()
    if Kernel._load then
      local t = love.timer.getTime()
        State = saves.read(Kernel._load)  --[[@as state]]
        if State.mode._mode.type == "escape_menu" then
          State.mode:close_menu()
        end
        Kernel._load = nil
        State.rails.runner:handle_loading()
      Kernel._total_time = math.max(Kernel._total_time - (love.timer.getTime() - t))
    end

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
      love.handlers[name](a,b,c,d,e,f)
    end

		dt = love.timer.step()
    Kernel._total_time = Kernel._total_time + dt
    Kernel._total_frames = Kernel._total_frames + 1

    for k, v in pairs(Kernel._delays) do
      Kernel._delays[k] = math.max(0, v - dt)
      if Kernel._delays[k] == 0 then
        love.keypressed(nil, k)
        Kernel._delays[k] = 1 / Kernel:get_key_rate(k)
      end
    end

		love.update(dt)

    love.graphics.origin()
    love.graphics.clear(love.graphics.getBackgroundColor())

    love.draw(dt)

    do
      local t = love.timer.getTime()
        love.graphics.present()
      Kernel._total_time = math.max(0, Kernel._total_time - (love.timer.getTime() - t))
    end

    if Kernel._save then
      local t = love.timer.getTime()
        saves.write(State, Kernel._save)
        Kernel._save = nil
      Kernel._total_time = math.max(0, Kernel._total_time - (love.timer.getTime() - t))
    end
  end
end
