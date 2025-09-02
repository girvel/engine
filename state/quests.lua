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
    order = {},
    has_new_content = false,
    items = {},
  }, mt)
end

methods.new_content_is_read = function(self)
  if not self.has_new_content then return end
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
