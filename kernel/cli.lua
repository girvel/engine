local cli = {}

cli.parse = function(args)
  local parser = Argparse()
    :name("Fallen engine")
    :description("Launch the game")

  parser:flag(
    "-d --debug",
    "Show FPS; no confirmation on exit, exit through Ctrl+D enabled;"
  )

  parser:option(
    "-s --enable-scenes"
  ):args("+"):default({})

  parser:option(
    "-S --disable-scenes"
  ):args("+"):default({})

  parser:flag(
    "-p --profiler",
    "Run the game with profiler"
  )

  parser:flag(
    "-A --disable-ambient",
    "Disables background music"
  )

  parser:option(
    "-r --resolution"
  ):args("?")

  parser:flag(
    "-F --fast-scenes",
    "Removes delays in scripts, sets high key rate for skipping lines"
  )

  args[-2] = nil
  args[-1] = nil

  if Table.last(args) == "-debug" then
    local ok, mobdebug = pcall(require, "mobdebug")
    assert(
      ok,
      "-debug option provided, but mobdebug is not found. Are you running this from ZeroBrane?"
    )

    mobdebug.start()
    table.remove(args)
  end

  local result = parser:parse(args)

  if result.resolution then
    result.resolution = result.resolution[1] or "1080p"
    local builtin_resolutions = {
      ["1080p"] = V(1920, 1080),
      ["720p"] = V(1280, 720),
      ["360p"] = V(640, 360),
    }

    assert(builtin_resolutions[result.resolution] or result.resolution:find("x"))

    result.resolution = builtin_resolutions[result.resolution]
      or Vector.own(Fun.iter(result.resolution / "x"):map(tonumber):totable())
  end

  return result
end

return cli
