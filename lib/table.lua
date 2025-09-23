--- Table extension modules
---
--- Contains additional functions for complex table manipulation
local tablex = {}

--- Returns the pairs-based entry count
--- @param t table
--- @return integer
tablex.count = function(t)
  local result = 0
  for _ in pairs(t) do
    result = result + 1
  end
  return result
end

--- Copies all fields into the base mutating first argument
-- Modifies first argument, copying all the fields via pairs of the following arguments in order
-- from left to right.
--- @param base table table to be changed
--- @param extension table table to copy fields from
--- @param ... table following extensions
--- @return table base the base table
tablex.extend = function(base, extension, ...)
  if extension == nil then return base end
  for k, v in pairs(extension) do
    base[k] = v
  end
  return tablex.extend(base, ...)
end

--- Sets values in base if they are nil
--- @generic T: table
--- @param base table?
--- @param defaults T
--- @return T
tablex.defaults = function(base, defaults)
  base = base or {}
  for k, v in pairs(defaults) do
    if base[k] == nil then
      base[k] = v
    end
  end
  return base
end

--- Concatenates lists into the base
-- Modifies first argument, copying all the fields via ipairs of the following arguments in order
-- from left to right
--- @param base table table to be changed
--- @param extension table table to copy fields from
--- @param ... table following extensions
--- @return table base the base table
tablex.concat = function(base, extension, ...)
  if extension == nil then return base end
  for _, v in ipairs(extension) do
    table.insert(base, v)
  end
  return tablex.concat(base, ...)
end

--- Concatenates and extends into the base
-- Modifies first argument, concatenating integer fields and copying all the key-value data, both 
-- in order from left to right
--- @param base table table to be changed
--- @param extension table? table to copy fields from
--- @param ... table following extensions
--- @return table base the base table
tablex.join = function(base, extension, ...)
  if extension == nil then return base end
  local length = #base
  for k, v in pairs(extension) do
    if type(k) == "number" and math.floor(k) == k then
      base[length + k] = v
    else
      assert(not base[k], ("collision during Table.join on key %s"):format(k))
      base[k] = v
    end
  end
  return tablex.join(base, ...)
end

--- Copies all fields to the base, merging them with existing tables recursively and mutating 
--- first argument
--- @param base table table to be changed
--- @param extension table table to copy fields from
--- @param ... table following extensions
--- @return table base the base table
tablex.merge = function(base, extension, ...)
  if extension == nil then return base end
  for k, v in pairs(extension) do
    if base[k] and type(base[k]) == "table" and type(v) == "table" then
      base[k] = tablex.merge({}, base[k], v)
    else
      base[k] = v
    end
  end
  return tablex.merge(base, ...)
end

--- Return the first index of the item in the table
--- @generic T
--- @param t T[]
--- @param item T
--- @return integer?
tablex.index_of = function(t, item)
  for i, x in ipairs(t) do
    if x == item then
      return i
    end
  end
  return nil
end

--- Return one of the keys of the item in the table
--- @param t table
--- @param item any
--- @return any
tablex.key_of = function(t, item)
  for k, v in pairs(t) do
    if v == item then
      return k
    end
  end
  return nil
end

--- Checks if the two tables are isomorphic on the first level on recursion
--- @param t1 table
--- @param t2 table
--- @return boolean
tablex.shallow_same = function(t1, t2)
  for k, v in pairs(t1) do
    if v ~= t2[k] then return false end
  end
  for k, _ in pairs(t2) do
    if not t1[k] then return false end
  end
  return true
end

--- @generic T: table
--- @param t T
--- @return T
tablex.shallow_copy = function(t)
  local result = setmetatable({}, getmetatable(t))
  for k, v in pairs(t) do
    result[k] = v
  end
  return result
end

--- @generic T: table
--- @param o T
--- @param seen? table
--- @return T
tablex.deep_copy = function(o, seen)
  seen = seen or {}
  if o == nil then return nil end
  if seen[o] then return seen[o] end

  local no
  if type(o) == 'table' then
    no = {}
    seen[o] = no

    for k, v in next, o, nil do
      no[tablex.deep_copy(k, seen)] = tablex.deep_copy(v, seen)
    end
    setmetatable(no, tablex.deep_copy(getmetatable(o), seen))
  else
    no = o
  end
  return no
end

--- @param t table
--- @param item any
--- @return table
tablex.remove = function(t, item)
  for k, v in pairs(t) do
    if v == item then
      if type(k) == "number" and math.ceil(k) == k then
        table.remove(t, k)
      else
        t[k] = nil
      end
    end
  end
  return t
end

--- @param t any[]
--- @param i integer
tablex.remove_breaking = function(t, i)
  t[i] = t[#t]
  t[#t] = nil
end

--- @param t any[]
--- @param indexes integer[]
tablex.remove_breaking_in_bulk = function(t, indexes)
  for i = #indexes, 1, -1 do
    tablex.remove_breaking(t, indexes[i])
  end
end

--- @param t table
--- @param item any
--- @return boolean
tablex.contains = function(t, item)
  for _, x in ipairs(t) do
    if x == item then
      return true
    end
  end
  return false
end

--- @generic T
--- @param t T[]
--- @return T
tablex.last = function(t)
  return t[#t]
end

--- @return table
tablex.pack = function(...)
  local n = select("#", ...)
  local result = {}
  for i = 1, n do
    result[i] = select(i, ...)
  end
  return result
end

--- Transforms list into a set
--- @generic T
--- @param list T[]
--- @return table<T, true?>
tablex.set = function(list)
  local result = {}
  for _, v in ipairs(list) do
    result[v] = true
  end
  return result
end

--- @param t table
--- @param fields string[]
tablex.assert_fields = function(t, fields)
  local missing_fields = {}
  for _, field in ipairs(fields) do
    if t[field] == nil then
      table.insert(missing_fields, field)
    end
  end
  if #missing_fields > 0 then
    error("fields %s are required for %s" % {table.concat(missing_fields, ", "), t})
  end
end

return tablex
