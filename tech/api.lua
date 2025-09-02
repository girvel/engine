local animated = require("engine.tech.animated")
local level = require("engine.tech.level")
local async = require("engine.tech.async")
local actions = require("engine.mech.actions")
local tcod = require("engine.tech.tcod")


--- API for asynchronous scripting, both AI and rails
local api = {}

--- @async
--- @param seconds number
api.wait = function(seconds)
  if not State.args.fast_scenes then
    async.sleep(seconds)
  end
end

--- @async
--- @param entity entity
--- @param destination vector
api.travel_scripted = function(entity, destination)
  api.travel_persistent(entity, destination, math.ceil((entity.position - destination):abs() / 3))

  local p = assert(State.grids.solids:find_free_position(destination))
  level.unsafe_move(entity, p)
end

--- @async
--- @param entity entity
--- @param destination vector
--- @param attempts_n? vector
api.travel_persistent = function(entity, destination, attempts_n)
  for _ = 1, attempts_n or 3 do
    api.travel(entity, destination)
    if entity.position == destination or (
      State.grids.solids:slow_get(destination, true)
      and (entity.position - destination):abs() == 1)
    then return end
    async.sleep(.5)
  end
end

--- @async
--- @param entity entity
--- @param destination vector
api.travel = function(entity, destination)
  if entity.position == destination or (
    State.grids.solids:slow_get(destination, true)
    and (entity.position - destination):abs() == 1)
  then return end

  local possible_destinations = {unpack(Vector.extended_directions)}
  table.sort(possible_destinations, function(a, b)
    local abs_a = a:abs()
    local abs_b = b:abs()
    if abs_a == abs_b then
      return (entity.position - destination - a):abs() < (entity.position - destination - b):abs()
    end

    return abs_a < abs_b
  end)
  table.insert(possible_destinations, 1, Vector.zero)

  local path
  for _, d in ipairs(possible_destinations) do
    path = tcod.snapshot(State.grids.solids):find_path(entity.position, destination + d)
    if #path > 0 then
      api.follow_path(entity, path)
      return
    end
  end
end

--- @param entity entity
--- @param path vector[]
api.follow_path = function(entity, path)
  for _, position in ipairs(path) do
    if entity.resources.movement <= 0 and not actions.dash:act(entity) then
      break
    end

    coroutine.yield()
    if Random.chance(.1) then coroutine.yield() end
    if not actions.move(position - entity.position):act(entity) then break end
    async.sleep(.25)
  end
end

--- @param entity entity
--- @param target entity
api.attack = function(entity, target)
  local direction = target.position - entity.position
  if direction:abs() ~= 1 then return end

  Log.debug("Attempt at attacking %s" % Entity.name(target))
  entity:rotate(direction)
  while actions.hand_attack:act(entity) or actions.offhand_attack:act(entity) do
    while not entity.animation.current:starts_with("idle") do
      coroutine.yield()
    end
  end
end

--- @async
--- @param source entity? no source == narration
--- @param text string
api.line = function(source, text)
  assert(
    State.rails.runner.locked_entities[State.player],
    "api.line shouldn't be called when the player is not locked into a cutscene"
  )

  local t = {
    type = "plain_line",
    source = source,
    text = text,
  }
  State.player.hears = t

  if source then
    State:add(animated.fx("engine/assets/sprites/animations/underfoot_circle", source.position))
  end

  while State.player.hears == t do
    coroutine.yield()
  end
end

--- @param options table<integer, string>
--- @param remove_picked? boolean
--- @return integer
api.options = function(options, remove_picked)
  State.player.hears = {
    type = "options",
    options = options,
  }

  while not State.player.speaks do
    coroutine.yield()
  end

  local result = State.player.speaks  --[[@as integer]]
  State.player.speaks = nil
  if remove_picked then
    options[result] = nil
  end

  return result
end

local prev_fov
local FADE_DURATION = .5

--- @async
api.fade_out = function()
  prev_fov = State.player.fov_r
  for i = prev_fov, 0, -1 do
    State.player.fov_r = i
    while not Period(FADE_DURATION / prev_fov, api.fade_out) do
      coroutine.yield()
    end
  end
end

--- @async
api.fade_in = function()
  for i = 0, prev_fov do
    State.player.fov_r = i
    while not Period(FADE_DURATION / prev_fov, api.fade_in) do
      coroutine.yield()
    end
  end
end

api.fade_move = function(position)
  local offset = State.perspective.camera_offset + State.player.position * State.level.cell_size * 4
  State.perspective.is_camera_following = false
  api.fade_out()
    level.slow_move(State.player, position)
    State.perspective.camera_offset = offset - State.player.position * State.level.cell_size * 4
    async.sleep(2)
  api.fade_in()
  State.perspective.is_camera_following = true
end

api.autosave = function()
  State.rails.runner:run_task(function()
    assert(
      not State.rails.runner.locked_entities[State.player],
      "Autosave when the player is locked in a cutscene"
    )
    Kernel:plan_save("autosave")
    Log.info("Autosave")
  end)
end

--- @param entity entity
--- @param target entity
api.rotate = function(entity, target)
  entity:rotate((target.position - entity.position):normalized2())
end

--- @param text string
api.notification = function(text)
  State.rails.runner:run_task(function()
    State.player.notification = text
    async.sleep(10)
    State.player.notification = nil
  end)
end

--- @return objective
api.journal_update = function()
  api.notification("Новая задача")
  State.quests.has_new_content = true
end

Ldump.mark(api, {}, ...)
return api
