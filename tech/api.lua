local async = require("engine.tech.async")
local actions = require("engine.mech.actions")
local tcod = require("engine.tech.tcod")


--- API for asynchronous scripting, both AI and rails
local api = {}

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

api.attack = function(entity, target)
  local direction = target.position - entity.position
  if direction:abs() ~= 1 then return end

  Log.debug("Attempt at attacking %s" % Entity.name(target))
  entity:rotate(direction)
  while entity:act(actions.hand_attack) or entity:act(actions.other_hand_attack) do
    while not entity.animation.current.codename:starts_with("idle") do
      coroutine.yield()
    end
  end
end

Ldump.mark(api, {}, ...)
return api
