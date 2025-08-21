local quests = {}

--- @class state_quests
local methods = {}
local mt = {__index = methods}

quests.new = function()
  return setmetatable({
    order = {"demo_1", "demo_2"},
    items = {
      demo_1 = {
        name = "Демонстрационный квест",
        objectives = {
          {
            text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
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

Ldump.mark(quests, {}, ...)
return quests
