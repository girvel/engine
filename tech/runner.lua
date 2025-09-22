local safety = require("engine.tech.safety")
local async = require("engine.tech.async")


local runner = {}

--- @alias rails_characters table<string, entity>

--- @class scene
--- @field characters? table<string, table>
--- @field start_predicate fun(scene, integer, characters): boolean
--- @field run fun(scene, characters)
--- @field enabled? true
--- @field boring_flag? true don't log scene beginning and ending
--- @field mode? "sequential"|"parallel"
--- @field save_flag? true don't warn about making a save during this scene
--- @field save_safety? fun(scene) runs when the scene run is discarded during loading

--- @class scene_run
--- @field coroutine thread
--- @field name string
--- @field base_scene scene

--- @class rails_runner
--- @field scenes table<string|integer, scene>
--- @field positions table<string, vector>
--- @field entities table<string, entity>
--- @field locked_entities table<entity, true>
--- @field _scene_runs scene_run[]
local methods = {}
local mt = {__index = methods}


--- @param scenes scene[]
--- @return rails_runner
runner.new = function(scenes, positions, entities)
  for _, scene in ipairs(State.args.enable_scenes) do
    scenes[scene].enabled = true
  end

  for _, scene in ipairs(State.args.disable_scenes) do
    scenes[scene].enabled = nil
  end

  return setmetatable({
    scenes = scenes,
    positions = positions,
    entities = entities,
    _scene_runs = {},
    locked_entities = {},
  }, mt)
end

local scene_run_mt = {}

local env

--- @param dt number
methods.update = function(self, dt)
  for scene_name, scene in pairs(self.scenes) do
    local characters = Fun.pairs(scene.characters or {})
      :map(function(name, opts) return name, self.entities[name] end)
      :tomap()

    if scene.enabled
      and (scene.mode == "parallel" or not self:is_running(scene))
      -- and (scene.in_combat_flag or not characters.player or not State.combat)
      and Fun.pairs(characters):all(function(_, c)
        return State:exists(c) and not self.locked_entities[c]
      end)
      and env(scene.start_predicate, scene, dt, characters)
    then
      for _, character in pairs(characters) do
        self.locked_entities[character] = true
      end
      -- outside coroutine to avoid two scenes with the same character starting in the same frame

      table.insert(self._scene_runs, setmetatable({
        coroutine = coroutine.create(function()
          if not scene.mode then
            scene.enabled = nil
          end

          if not scene.boring_flag then
            Log.info("Scene %q starts" % {scene_name})
          end

          safety.call(scene.run, scene, characters)

          for _, character in pairs(characters) do
            self.locked_entities[character] = nil
          end

          if not scene.boring_flag then
            Log.info("Scene %q ends" % {scene_name})
          end
        end),
        base_scene = scene,
        name = scene_name,
      }, scene_run_mt))
    end
  end

  local indexes_to_remove = {}
  for i, run in ipairs(self._scene_runs) do
    env(async.resume, run.coroutine)

    if coroutine.status(run.coroutine) == "dead" then
      table.insert(indexes_to_remove, i)
    end
  end

  Table.remove_breaking_in_bulk(self._scene_runs, indexes_to_remove)
end

--- @param scene string|scene
methods.is_running = function(self, scene)
  if type(scene) == "string" then
    scene = self.scenes[scene]
  end

  return Fun.iter(self._scene_runs)
    :any(function(r) return r.base_scene == scene end)
end

--- @param scene string|scene
methods.stop = function(self, scene)
  if type(scene) == "string" then
    scene = self.scenes[scene]
  end

  local old_length = #self._scene_runs

  self._scene_runs = Fun.iter(self._scene_runs)
    :filter(function(r) return r.base_scene ~= scene end)
    :totable()

  coroutine.yield()
  for character, _ in pairs(scene.characters or {}) do
    self.locked_entities[self.entities[character]] = nil
  end

  Log.info("Stopping scene %s; interrupted %s runs" % {
    Table.key_of(self.scenes, scene),
    old_length - #self._scene_runs,
  })
end

--- @param scene string|scene
methods.remove = function(self, scene)
  self:stop(scene)
  local key = type(scene) == "string" and scene or Table.key_of(self.scenes, scene)
  self.scenes[key] = nil
  Log.info("Removed scene %s")
end

--- @param f fun(scene, characters)
methods.run_task = function(self, f)
  local key
  for i = 1, math.huge do
    key = "task_" .. i
    if not self.scenes[key] then break end
  end

  local end_promise = Promise.new()
  local scene = {
    boring_flag = true,
    enabled = true,
    start_predicate = function() return true end,
    run = function(self_scene)
      f(self_scene)
      end_promise:resolve()
      self.scenes[key] = nil  -- not in the beginning: sometimes scene should handle save_safety
    end,
  }
  self.scenes[key] = scene
  return end_promise, scene
end

methods.handle_loading = function(self)
  for _, scene in pairs(self.scenes) do
    if scene.save_safety then
      scene:save_safety()
    end
  end
end

scene_run_mt.__serialize = function(self)
  if not self.base_scene.save_flag and not self.base_scene.save_safety then
    Log.warn("Scene %s is active when saving" % {self.name})
  end
  return "nil"
end

env = function(f, ...)
  Runner = State.rails.runner
  local result = f(...)
  Runner = (nil --[[@as rails_runner]])
  return result
end

Ldump.mark(runner, {}, ...)
return runner
