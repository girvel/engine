return function()
  if not State.debug and State.mode:attempt_exit() then return true end

  Log.info("Exited smoothly")
  if State.args.profiler then
    Log.info(Profile.report(100))
  end
  local line_report = Lp.report()
  if #line_report > 0 then
    Log.info(line_report)
  end
  Log.report()
  return false
end
