local animated = require("engine.tech.animated")
local level = require("engine.tech.level")
local async = require("engine.tech.async")
local actions = require("engine.mech.actions")
local tcod = require("engine.tech.tcod")
local sound = require("engine.tech.sound")
local fighter = require("engine.mech.class.fighter")


--- @param x entity|vector
--- @return vector
local to_vector = function(x)
  if getmetatable(x) ~= Vector.mt then
    if not x.position then
      Error("Entity %s has no position", x)
    end
    return x.position
  end  --- @cast x vector
  return x
end


--- API for asynchronous scripting, both AI and rails
local api = {}

--- @param secs number
--- @return promise, scene
api.delay = function(secs)
  return State.runner:run_task(function()
    async.sleep(secs)
  end, "api_delay")
end

--- @param crowd entity[]
--- @param destination vector
--- @param rotate_towards? vector
--- @return promise, scene[]
api.travel_crowd = function(crowd, destination, rotate_towards)
  local promises = {}
  local scenes = {}

  for _, e in ipairs(crowd) do
    if State:exists(e) then
      local p, s = State.runner:run_task(function()
        api.travel_persistent(e, destination, 2)
        if rotate_towards then
          api.rotate(e, rotate_towards)
        end
      end)
      table.insert(promises, p)
      table.insert(scenes, s)
    end
  end

  return Promise.all(unpack(promises)), scenes
end

--- @param entity entity
--- @param position vector
--- @param suppress_warning? boolean
api.assert_position = function(entity, position, suppress_warning)
  if entity.position == position then return end
  local prev_position = entity.position

  if not suppress_warning then
    Log.warn(
      "Entity %s mispositioned at %s; should be at %s; placing at %s",
      entity, entity.position, position, position
    )
  end

  local prev = State.grids[entity.grid_layer][position]
  if prev then
    State.grids[entity.grid_layer][position] = nil
  end
  level.unsafe_move(entity, position)
  if prev then
    State.grids[entity.grid_layer][prev_position] = prev
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
--- @param destination vector|entity
--- @return promise, scene
api.travel_scripted = function(entity, destination, speed)
  destination = to_vector(destination)

  local promise, scene = State.runner:run_task(function()
    local ok = api.travel_persistent(
      entity, destination, math.max(1, math.ceil((entity.position - destination):abs2() / 3)), speed
    )
    if ok then return end

    local p = assert(State.grids.solids:find_free_position(destination))
    level.unsafe_move(entity, p)
  end, "travel_scripted_" .. Name.code(entity, "anon"))

  scene.on_cancel = function()
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
api.travel_persistent = function(entity, destination, attempts_n, speed)
  for _ = 1, attempts_n or 3 do
    api.travel(entity, destination, false, speed)
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
--- @param uses_dash? boolean
--- @param speed? number
--- @return boolean
api.travel = function(entity, destination, uses_dash, speed)
  if entity.position == destination or (
    State.grids.solids:slow_get(destination, true)
    and (entity.position - destination):abs2() == 1)
  then return true end

  local path = api.build_path(entity.position, destination)
  if not path then return false end
  return api.follow_path(entity, path, uses_dash, speed)
end

local vision_map = Memoize(function()
  return tcod.map(State.grids.solids)
end)

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
      path = vision_map():find_path(start, destination + d)
      if #path > 0 then
        return path
      end
    end
  end
end

--- @async
--- @param entity entity
--- @param path vector[]
--- @param uses_dash? boolean
--- @param speed? number
--- @return boolean
api.follow_path = function(entity, path, uses_dash, speed)
  speed = speed or entity.speed or 5

  for _, position in ipairs(path) do
    if entity.resources.movement <= 0 and not (uses_dash and actions.dash:act(entity)) then
      return false
    end
    if entity.position == Table.last(path) then break end

    coroutine.yield()
    if Random.chance(.1) then coroutine.yield() end
    if not actions.move(position - entity.position):act(entity) then break end
    async.sleep(1 / speed)
  end

  return true
end

--- @param entity entity
--- @param target entity
api.attack = function(entity, target)
  local direction = target.position - entity.position
  if direction:abs2() ~= 1 then return end

  Log.debug("Attempt at attacking %s", Name.code(target))
  entity:rotate(direction)

  fighter.action_surge:act(entity)
  while true do
    if not actions.hand_attack:is_available(entity)
      and not actions.offhand_attack:is_available(entity)
    then
      break
    end

    while not entity.animation.current:starts_with("idle") do
      coroutine.yield()
    end

    if not actions.hand_attack:act(entity)
      and not actions.offhand_attack:act(entity)
    then
      break
    end
  end
end

--- @async
--- @param source entity? no source == narration
--- @param text string
api.line = function(source, text)
  assert(
    State.runner.locked_entities[State.player],
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

--- @param duration? number
--- @return promise, scene
api.fade_out = function(duration)
  if prev_fov then
    Error("Can not fade out twice")
  end

  duration = duration or FADE_DURATION

  local promise, scene = State.runner:run_task(function()
    prev_fov = State.player.fov_r
    for i = prev_fov, 0, -1 do
      State.player.fov_r = i
      while not State.period:absolute(duration / prev_fov, api.fade_in) do
        coroutine.yield()
      end
    end
  end, "fade_out")

  scene.on_cancel = function()
    State.player.fov_r = prev_fov
    prev_fov = nil
  end

  return promise, scene
end

--- @param duration? number
--- @return promise, scene
api.fade_in = function(duration)
  if not prev_fov then
    Error("Can not fade in if there was no fade out")
  end

  duration = duration or FADE_DURATION

  local promise, scene = State.runner:run_task(function()
    for i = 0, prev_fov do
      State.player.fov_r = i
      while not State.period:absolute(duration / prev_fov, api.fade_in) do
        coroutine.yield()
      end
    end
    prev_fov = nil
  end, "fade_in")

  scene.on_cancel = function()
    State.player.fov_r = prev_fov
    prev_fov = nil
  end

  return promise, scene
end

--- @param position vector
--- @return promise, scene
api.move_camera = function(position)
  return State.runner:run_task(function()
    State.perspective.is_camera_following = true
    --- @diagnostic disable-next-line
    State.perspective.target_override = {position = position}
    coroutine.yield()
    while State.perspective.is_moving do coroutine.yield() end
    State.perspective.target_override = nil
    State.perspective.is_camera_following = false
  end, "move_camera")
end

api.free_camera = function()
  return State.runner:run_task(function()
    --- @diagnostic disable-next-line
    State.perspective.target_override = nil
    State.perspective.is_camera_following = true
    coroutine.yield()
    while State.perspective.is_moving do coroutine.yield() end
  end, "free_camera")
end

--- @param name? string
api.autosave = function(name)
  if State.runner.save_lock then
    -- Autosave collision is intended behaviour; it just means that they are joined into one
    return
  end

  name = name or "autosave"

  local _, scene = State.runner:run_task(function()
    Log.debug("Planned autosave %q", name)

    while State.runner.locked_entities[State.player] or State.combat do
      coroutine.yield()
    end

    if State.player.hp > 0 then
      Log.info("Autosave %q", name)
      Kernel:plan_save(name)

      coroutine.yield()
      api.notification("Игра сохранена")
    else
      Log.info("No autosave %q, player is dead", name)
    end
    State.runner.save_lock = false
  end, "autosave_" .. (name or "anon"))

  scene.on_cancel = function()
    State.runner.save_lock = false
  end
  State.runner.save_lock = scene
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
  local _, scene = State.runner:run_task(function()
    State.player.notification = text
    async.sleep(5)
    State.player.notification = nil
  end, "notification")

  scene.on_cancel = function()
    if State.player.notification == text then
      State.player.notification = nil
    end
  end
end

--- @param kind "new_task"|"task_completed"
api.journal_update = function(kind)
  local text
  if kind == "new_task" then
    text = "Новая задача"
  elseif kind == "task_completed" then
    text = "Задача выполнена"
  else
    Error("Unknown journal update %s", kind)
  end
  api.notification(text)
  State.quests.has_new_content = true
end

--- @param duration number time to full saturation in seconds
--- @param color vector
--- @return promise, scene
api.curtain = function(duration, color)
  return State.runner:run_task(function()
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
  end, "curtain")
end

--- @param target vector|entity
--- @return boolean
api.is_visible = function(target)
  target = to_vector(target):map(math.floor)

  if not (
    State.perspective.vision_start <= target
    and target <= State.perspective.vision_end
  ) then
    return false
  end

  local player_vision = State.player.ai._vision_map
  if not player_vision then return false end

  if not State.grids.solids:can_fit(target) then return false end
  return player_vision:is_visible_unsafe(unpack(target))
end

--- @param path string
--- @param volume? number
--- @return promise, scene
api.play_sound = function(path, volume)
  return State.runner:run_task(function()
    local s = sound.multiple(path, volume):play()
    while s.source:isPlaying() do
      coroutine.yield()
    end
  end, "play " .. path)
end

--- @param a entity|vector
--- @param b entity|vector
--- @return number
api.distance = function(a, b)
  a = to_vector(a)
  b = to_vector(b)
  return (a - b):abs2()
end

Ldump.mark(api, {}, ...)
return api
