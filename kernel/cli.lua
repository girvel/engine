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

  args[-2] = nil
  args[-1] = nil

  return parser:parse(args)
end

return cli
