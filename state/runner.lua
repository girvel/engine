local safety = require("engine.tech.safety")
local async = require("engine.tech.async")


local runner = {}

--- @alias runner_characters table<string, entity>
--- @alias runner_positions table<string, vector>
--- @alias runner_scenes table<string|integer, scene|table>

--- @class scene
--- @field characters? table<string, table>
--- @field start_predicate fun(self: scene|table, dt: integer, ch: runner_characters, ps: runner_positions): boolean|any, ...
--- @field run fun(self: scene|table, ch: runner_characters, ps: runner_positions, ...): any
--- @field enabled? boolean
--- @field boring_flag? true don't log scene beginning and ending
--- @field mode? "sequential"|"parallel"|"once"
--- @field save_flag? true don't warn about making a save during this scene
--- @field in_combat_flag? true allows scene to start in combat
--- @field on_add? fun(self: scene|table, ch: runner_characters, ps: runner_positions) runs when the scene is added
--- @field on_cancel? fun(self: scene|table) runs when the scene run is cancelled (either through runner:stop, runner:remove or loading a save)

--- @class scene_run
--- @field coroutine thread
--- @field name string
--- @field base_scene scene

--- @class state_runner
--- @field scenes runner_scenes
--- @field positions table<string, vector>
--- @field entities table<string, entity>
--- @field locked_entities table<entity, true>
--- @field save_lock scene?
--- @field _scene_runs scene_run[]
local methods = {}
local mt = {__index = methods}


--- @return state_runner
runner.new = function()
  return setmetatable({
    scenes = {},
    positions = Table.strict({}, "runner position"),
    entities = Table.strict({}, "runner entity"),
    _scene_runs = {},
    locked_entities = {},
  }, mt)
end

local scene_run_mt = {}

--- @param dt number
methods.update = function(self, dt)
  for scene_name, scene in pairs(self.scenes) do
    local characters = Table.strict(
      Fun.pairs(scene.characters or {})
        :map(function(name, opts)
          return name, assert(
            self.entities[name],
            ("Character %q does not exist in State.runner.entities"):format(name)
          )
        end)
        :tomap(),
      ("scene %q's character"):format(scene_name)
    )

    if not (scene.enabled
      and (not self.save_lock or self.save_lock == scene or scene.on_cancel)
      and (scene.mode == "parallel" or not self:is_running(scene))
      and (scene.in_combat_flag or not State.combat or Table.count(characters) == 0)
      and Fun.pairs(characters):all(function(_, c)
        return State:exists(c) and not self.locked_entities[c]
      end))
    then
      goto continue
    end

    local args = {scene:start_predicate(dt, characters, self.positions)}
    if not args[1] then goto continue end

    -- outside coroutine to avoid two scenes with the same character starting in the same frame
    for _, character in pairs(characters) do
      self.locked_entities[character] = true
    end

    table.insert(self._scene_runs, setmetatable({
      coroutine = coroutine.create(function()
        if not scene.mode then
          scene.enabled = nil
        end

        if not scene.boring_flag then
          Log.info("Scene %q starts", scene_name)
        end

        safety.call(scene.run, scene, characters, self.positions, unpack(args))

        for _, character in pairs(characters) do
          self.locked_entities[character] = nil
        end

        if Table.key_of(characters, State.player) then
          State.perspective.target_override = nil
          State.perspective.is_camera_following = true
          State.player.curtain_color = Vector.transparent
        end

        if not scene.boring_flag then
          Log.info("Scene %q ends", scene_name)
        end

        if scene.mode == "once" then
          self:remove(scene)
        end
      end),
      base_scene = scene,
      name = scene_name,
    }, scene_run_mt))

    ::continue::
  end

  local to_remove = {}
  local runs_copy = Table.shallow_copy(self._scene_runs)
  -- State.runner:stop may change this collection

  for i, run in ipairs(runs_copy) do
    local ok, message = pcall(async.resume, run.coroutine)
    if not ok then
      Log.trace(run)
      error(message)
    end

    if coroutine.status(run.coroutine) == "dead" then
      to_remove[run] = true
    end
  end

  -- can't use runs_copy anymore -- could be changed
  self._scene_runs = Fun.iter(self._scene_runs)
    :filter(function(run) return not to_remove[run] end)
    :totable()
end

--- @param scene integer|string|scene
methods.is_running = function(self, scene)
  if type(scene) ~= "table" then
    scene = self.scenes[scene]
  end

  return Fun.iter(self._scene_runs)
    :any(function(r) return r.base_scene == scene end)
end

--- @async
--- @param scene integer|string|scene
methods.stop = function(self, scene)
  if type(scene) ~= "table" then
    scene = self.scenes[scene]
  end

  local old_length = #self._scene_runs

  self._scene_runs = Fun.iter(self._scene_runs)
    :filter(function(r) return r.base_scene ~= scene end)
    :totable()

  local new_length = #self._scene_runs

  local did_on_cancel_run = false
  if new_length ~= old_length then
    coroutine.yield()
    for character, _ in pairs(scene.characters or {}) do
      self.locked_entities[self.entities[character]] = nil
    end

    if scene.characters and scene.characters.player then
      State.perspective.target_override = nil
      State.perspective.is_camera_following = true
      State.player.curtain_color = Vector.transparent
    end

    if scene.on_cancel then
      did_on_cancel_run = true
      scene:on_cancel()
    end
  end

  Log.info("Stopping scene %s; interrupted %s runs%s",
    Table.key_of(self.scenes, scene) or Inspect(scene),
    old_length - new_length,
    did_on_cancel_run and "; used :on_cancel" or ""
  )
end

--- @param scenes runner_scenes
methods.add = function(self, scenes)
  Table.extend_strict(self.scenes, scenes)
  local on_adds_repr = ""
  for name, scene in pairs(scenes) do
    if scene.on_add then
      scene:on_add(self.entities, self.positions)
      on_adds_repr = on_adds_repr .. "\n  " .. name .. ":on_add()"
    end

    if Table.contains(State.args.enable_scenes, name) then
      scene.enabled = true
    end

    if Table.contains(State.args.disable_scenes, name) then
      scene.enabled = nil
    end
  end

  Log.info("Added %s scenes%s", Table.count(scenes), on_adds_repr)
end

--- @param scene integer|string|scene
methods.remove = function(self, scene)
  local key = type(scene) ~= "table" and scene or Table.key_of(self.scenes, scene)
  if not key then return end
  self.scenes[key] = nil
  Log.info("Removed scene %s", key)
  self:stop(scene)  -- yields => goes last
end

--- @param f fun(scene, characters)
--- @param name? string
--- @return promise, scene
methods.run_task = function(self, f, name)
  local key = ("%s_%s"):format(name or "task", State.uid:next())

  local end_promise = Promise.new()
  local scene = {
    boring_flag = true,
    enabled = true,
    start_predicate = function() return true end,
    run = function(self_scene)
      f(self_scene)
      end_promise:resolve()
      self.scenes[key] = nil  -- not in the beginning: sometimes scene should handle on_cancel
    end,
  }
  self.scenes[key] = scene
  return end_promise, scene
end

methods.handle_loading = function(self)
  for name, scene in pairs(self.scenes) do
    if scene.on_cancel then
      scene:on_cancel()
      Log.debug("Scene %s safely cancelled in save", name)
    end
  end
end

scene_run_mt.__serialize = function(self)
  if not self.base_scene.save_flag and not self.base_scene.on_cancel then
    Log.warn("Scene %s cancelled in save with no :on_cancel defined", self.name)
  end
  return "nil"
end

Ldump.mark(runner, {}, ...)
return runner
