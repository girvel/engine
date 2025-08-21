local quests = {}

--- @class quest
--- @field name string
--- @field objectives objective[]

--- @class objective
--- @field text string
--- @field status "new"|"active"|"done"|"failed"

--- @class state_quests
--- @field order string[]
--- @field has_new_content boolean
--- @field items table<string, quest>
local methods = {}
local mt = {__index = methods}

quests.new = function()
  return setmetatable({
    order = {"demo_1", "demo_2"},
    has_new_content = true,
    items = {
      demo_1 = {
        name = "Демонстрационный квест",
        objectives = {
          {
            text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
            status = "new",
          },
          {
            text = "Вторая задача",
            status = "done",
          },
          {
            text = "Третья задача",
            status = "failed",
          },
        },
      },
      demo_2 = {
        name = "Другой квест (тоже демонстрационный)",
        objectives = {
          {
            text = "Первая задача",
            status = "active",
          },
          {
            text = "Вторая задача",
            status = "done",
          },
          {
            text = "Третья задача",
            status = "failed",
          },
        },
      }
    },
  }, mt)
end

methods.new_content_is_read = function(self)
  for _, quest in pairs(self.items) do
    for _, objective in ipairs(quest.objectives) do
      if objective.status == "new" then
        objective.status = "active"
      end
    end
  end
  self.has_new_content = false
end

Ldump.mark(quests, {}, ...)
return quests
