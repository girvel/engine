local cli = {}

cli.parse = function(args)
  local parser = Argparse()
    :name("Fallen engine")
    :description("Launch the game")

  parser:flag(
    "-d --debug",
    "Show FPS; no confirmation on exit, exit through Ctrl+D enabled;"
  )

  parser:flag(
    "-r --recover",
    "Launch lua shell instead of the game"
  )

  parser:option(
    "-s --enable-scenes",
    "Sets `disabled = false` for given scene identifiers"
  ):args("+"):default({})

  parser:option(
    "-S --disable-scenes",
    "Sets `disabled = true` for given scene identifiers"
  ):args("+"):default({})

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

  return parser:parse(args)
end

return cli
