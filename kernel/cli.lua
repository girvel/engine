local cli = {}

cli.parse = function(args)
  local parser = Argparse()
    :name("Fallen engine")
    :description("Launch the game")

  parser:flag(
    "-d --debug",
    "Show FPS"
  )

  args[-2] = nil
  args[-1] = nil

  return parser:parse(args)
end

return cli
