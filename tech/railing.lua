local async = require("engine.tech.async")


local railing = {}

--- @class scene
--- @field start_predicate fun(scene, integer)
--- @field run fun(scene)
--- @field disabled? true
--- @field boring_flag? true don't log scene beginning and ending
--- @field multiple_times_flag? true don't disable the scene in the beginning of the first run

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
railing.runner = function(scenes, positions, entities)
  return setmetatable({
    scenes = scenes,
    positions = positions,
    entities = entities,
    _scene_runs = {},
    locked_entities = {},
  }, mt)
  -- NEXT (rails) handle positions, entities
end

--- @param dt number
methods.update = function(self, dt)
  for scene_name, scene in pairs(self.scenes) do
    -- NEXT (rails) characters

    if not scene.disabled
      -- NEXT (rails)
      -- and (scene.multiple_instances_flag or not self:is_running(scene))
      -- and (scene.in_combat_flag or not characters.player or not State.combat)
      -- and Fun.pairs(characters):all(function(_, c) return State:exists(c) end)
      and scene:start_predicate(dt, characters)
    then
      table.insert(self._scene_runs, {
        coroutine = coroutine.create(function()
          if not scene.multiple_times_flag then
            scene.disabled = true
          end

          if not scene.boring_flag then
            Log.info("Scene %q starts" % {scene_name})
          end

          -- for _, character in pairs(characters) do
          --   Query(character).ai.in_cutscene_flag = true
          -- end

          -- run the body
          -- if failed
          --   if debug mode
          --     update stack
          --     launch debug shell
          --   else
          --     log the stack trace
          --     reset blackout
          -- else
          --   proceed
          -- reset in_cutscene
          -- log ending

          -- NEXT (safety) safe call
          -- Debug.call(scene.run, scene, self, characters)
          scene:run(characters)

          -- for _, character in pairs(characters) do
          --   Query(character).ai.in_cutscene_flag = nil
          -- end

          if not scene.boring_flag then
            Log.info("Scene %q ends" % {scene_name})
          end
        end),
        base_scene = scene,
        name = scene_name,
      })
    end
  end

  local indexes_to_remove = {}
  for i, run in ipairs(self._scene_runs) do
    async.resume(run.coroutine)
    if coroutine.status(run.coroutine) == "dead" then
      table.insert(indexes_to_remove, i)
    end
  end

  Table.remove_breaking_in_bulk(self._scene_runs, indexes_to_remove)
end

Ldump.mark(railing, {}, ...)
return railing
