local player = {}

player.base = function()
  return {
    codename = "player",
    player_flag = true,
    fov_r = 15,

    -- ai = {
    --   next_action = nil,
    --   run = function(entity, dt)
    --     if entity.ai.next_action then
    --       
    --     end
    --   end,
    -- },
  }
end

Ldump.mark(player, {}, ...)
return player
