local animated = require("engine.tech.animated")
local level = require("engine.tech.level")
local async = require("engine.tech.async")
local actions = require("engine.mech.actions")
local tcod = require("engine.tech.tcod")
local sound= require("engine.tech.sound")
local iteration = require("engine.tech.iteration")


--- API for asynchronous scripting, both AI and rails
local api = {}

--- @async
--- @param seconds number
api.wait = function(seconds)
  if not State.args.fast_scenes then
    async.sleep(seconds)
  end
end

--- @param entity entity
--- @param intermediate_point vector
--- @param destination vector
--- @return promise, scene
api.fast_travel = function(entity, intermediate_point, destination)
  local promise, scene = api.travel_scripted(entity, intermediate_point)
  promise:next(function()
    local p = State.grids.solids:find_free_position(destination)
    level.unsafe_move(entity, p or destination)
  end)
  return promise, scene
end

--- @param entity entity
--- @param destination vector
--- @return promise, scene
api.travel_scripted = function(entity, destination)
  local promise, scene = State.rails.runner:run_task(function()
    local ok = api.travel_persistent(
      entity, destination, math.ceil((entity.position - destination):abs2() / 3)
    )
    if ok then return end

    local p = assert(State.grids.solids:find_free_position(destination))
    level.unsafe_move(entity, p)
  end)
  scene.save_safety = function()
    local p = assert(State.grids.solids:find_free_position(destination))
    level.unsafe_move(entity, p)
    promise:resolve()
  end
  return promise, scene
end

--- @async
--- @param entity entity
--- @param destination vector
--- @param attempts_n? vector
--- @return boolean
api.travel_persistent = function(entity, destination, attempts_n)
  for _ = 1, attempts_n or 3 do
    api.travel(entity, destination)
    if entity.position == destination then return true end
    local d = destination - entity.position
    if State.grids.solids:slow_get(destination, true) and d:abs2() == 1 then
      entity:rotate(d)
      return true
    end
    async.sleep(.5)
  end
  return false
end

--- @async
--- @param entity entity
--- @param destination vector
api.travel = function(entity, destination)
  Log.trace("travel", Name.code(entity), entity.position, destination)
  if entity.position == destination or (
    State.grids.solids:slow_get(destination, true)
    and (entity.position - destination):abs2() == 1)
  then return end

  local path = api.build_path(entity.position, destination)
  if path then
    api.follow_path(entity, path)
  end
end

--- @param start vector
--- @param destination vector
--- @return vector[]?
api.build_path = function(start, destination)
  local possible_destinations = {unpack(Vector.extended_directions)}
  table.sort(possible_destinations, function(a, b)
    local abs_a = a:abs2()
    local abs_b = b:abs2()
    if abs_a == abs_b then
      return (start - destination - a):abs2() < (start - destination - b):abs2()
    end

    return abs_a < abs_b
  end)
  table.insert(possible_destinations, 1, Vector.zero)

  local path
  for _, d in ipairs(possible_destinations) do
    local p = destination + d
    if State.grids.solids:can_fit(p) then
      path = tcod.snapshot(State.grids.solids):find_path(start, destination + d)
      if #path > 0 then
        return path
      end
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
    if entity.position == Table.last(path) then break end

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
  if direction:abs2() ~= 1 then return end

  Log.debug("Attempt at attacking %s" % Name.code(target))
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

--- @param position vector
--- @return promise, scene
api.move_camera = function(position)
  return State.rails.runner:run_task(function()
    State.perspective.is_camera_following = true
    --- @diagnostic disable-next-line
    State.perspective.target_override = {position = position}
    coroutine.yield()
    while State.perspective.is_moving do coroutine.yield() end
    State.perspective.target_override = nil
    State.perspective.is_camera_following = false
  end)
end

api.free_camera = function()
  return State.rails.runner:run_task(function()
    --- @diagnostic disable-next-line
    State.perspective.target_override = nil
    State.perspective.is_camera_following = true
    coroutine.yield()
    while State.perspective.is_moving do coroutine.yield() end
  end)
end

--- @param name? string
api.autosave = function(name)
  State.rails.runner:run_task(function()
    Log.debug("Planned autosave")
    while State.rails.runner.locked_entities[State.player] do
      coroutine.yield()
    end
    -- assert(
    --   not State.rails.runner.locked_entities[State.player],
    --   "Autosave when the player is locked in a cutscene"
    -- )
    Kernel:plan_save(name or "autosave")
    Log.info("Autosave")
  end)
  api.notification("Игра сохранена")
end

--- @param entity entity
--- @param target entity|vector
api.rotate = function(entity, target)
  local d = (getmetatable(target) == Vector.mt and target or target.position) - entity.position
  if d == Vector.zero then return end
  entity:rotate(d:normalized2())
end

local NOTIFICATION_SOUND = sound.multiple("engine/assets/sounds/notification", .01)

--- @param text string
api.notification = function(text)
  NOTIFICATION_SOUND:play()
  State.rails.runner:run_task(function()
    State.player.notification = text
    async.sleep(5)
    State.player.notification = nil
  end)
end

--- @param kind "new_task"|"task_completed"
api.journal_update = function(kind)
  local text
  if kind == "new_task" then
    text = "Новая задача"
  elseif kind == "task_completed" then
    text = "Задача выполнена"
  else
    assert(false, ("Unknown journal update %s"):format(kind))
  end
  api.notification(text)
  State.quests.has_new_content = true
end

--- @param duration number time to full saturation in seconds
--- @param color vector
--- @return promise, scene
api.curtain = function(duration, color)
  return Runner:run_task(function()
    local start_time = love.timer.getTime()
    local start_color = State.player.curtain_color
    local dcolor = color - start_color
    while true do
      local dt = love.timer.getTime() - start_time
      if dt >= duration then
        break
      end
      State.player.curtain_color = start_color + dcolor * (dt / duration)
      coroutine.yield()
    end
    State.player.curtain_color = color
  end)
end

Ldump.mark(api, {}, ...)
return api
