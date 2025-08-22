local rl = require("engine.lib.rl")


local shell = {}

local execute

shell.run = function()
  while true do
    local command = rl.readline("> ")
    if not command then break end
    execute(command)
  end
end

execute = function(command)
  if not command:find("=") then
    command = "return " .. command
  end

  local f, msg = loadstring(command, "shell")
  if not f then
    print(msg)
    return
  end

  local ok, result = pcall(f)
  if ok then
    if result then
      print(Inspect(result))
    end
  else
    print(result)
  end
end

return shell
