--- Module for simplifying palette creation
local factoring = {}

local get_atlas_quad

--- @param atlas_path string
--- @param codenames (string | boolean)[]
--- @param mixin? fun(string): table
--- @return {[string | integer]: function}
factoring.from_atlas = function(atlas_path, cell_size, codenames, mixin)
  local result = {ATLAS_IMAGE = love.graphics.newImage(atlas_path)}
  local w, h = result.ATLAS_IMAGE:getDimensions()
  for i, codename in ipairs(codenames) do
    if not codename then goto continue end
    local current_mixin = mixin and mixin(codename) or {}
    local factory = function()
      return Table.extend({
        codename = codename,
        sprite = {
          type = "atlas",
          quad = get_atlas_quad(i, cell_size, w, h),
        }
      }, current_mixin)
    end

    result[i] = factory
    result[codename] = factory
    ::continue::
  end
  return result
end

get_atlas_quad = function(index, cell_size, atlas_w, atlas_h)
  local w = atlas_w
  local x = (index - 1) * cell_size
  return love.graphics.newQuad(
    x % w, math.floor(x / w) * cell_size, cell_size, cell_size, atlas_w, atlas_h
  )
end

Ldump.mark(factoring, {}, ...)
return factoring
