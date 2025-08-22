--- @param self state_mode_game
--- @param entity table
--- @param dt number
local draw_entity = function(self, entity, dt)
  local current_view = State.perspective.views[entity.view]
  local offset_position = entity.position
  if entity.layer then
    offset_position = offset_position * State.level.cell_size
  end
  offset_position = current_view:apply(offset_position)
  local x, y = unpack(offset_position)

  if entity.shader then
    love.graphics.setShader(entity.shader.love_shader)
    love.graphics.setCanvas(self._temp_canvas)
    love.graphics.clear()
    if entity.shader.preprocess then
      entity.shader:preprocess(entity, dt)
    end
  end

  -- NEXT global shader
  -- NEXT inventory
  -- NEXT text?

  local sprite = entity.sprite
  if sprite.type == "image" or (sprite.type == "atlas" and entity.shader) then
    local display_slot, is_hand_bg, is_offhand_bg
    if entity.inventory then
      display_slot = function(slot)
        local this_item = entity.inventory[slot]
        if not this_item then return end

        local item_sprite = this_item.sprite
        local entity_anchor = entity.sprite.anchors[slot]
        local item_anchor = item_sprite.anchors.parent
        local item_x, item_y = x, y
        if entity_anchor and item_anchor then
          local offset = (entity_anchor - item_anchor):mul_mut(current_view.scale)
          item_x = item_x + offset[1]
          item_y = item_y + offset[2]
        end
        love.graphics.draw(item_sprite.image, item_x, item_y, 0, current_view.scale)
      end

      is_hand_bg = entity.direction == Vector.up
      is_offhand_bg = entity.direction ~= Vector.down

      if is_hand_bg then display_slot("hand") end
      if is_offhand_bg then display_slot("offhand") end
    end

    love.graphics.draw(entity.sprite.image, x, y, 0, current_view.scale)

    if entity.inventory then
      display_slot("body")
      display_slot("head")
      display_slot("blood")
      display_slot("gloves")
      if not is_hand_bg then display_slot("hand") end
      if not is_offhand_bg then display_slot("offhand") end
      display_slot("highlight")
    end
  elseif sprite.type == "atlas" then
    self._sprite_batches[entity.layer]:add(sprite.quad, x, y, 0, current_view.scale)
  end

  if entity.shader then
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.draw(self._temp_canvas)
  end
end

return draw_entity
