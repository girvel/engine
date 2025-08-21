local old_serialize = getmetatable(Ldump.serializer).__call
Ldump.serializer = setmetatable({
  handlers = Ldump.serializer.handlers,
}, {
  __call = function(self, x)
    local a, b = old_serialize(self, x)
    if a then
      return a, b
    end
    if type(x) == "userdata"
      and x.typeOf
      and x:typeOf("ImageData")
    then
      --- @cast x love.ImageData
      local repr = x:encode("png"):getString()
      return function()
        return love.image.newImageData(
          love.filesystem.newFileData(repr, "tmp.png")
        )
      end
    end
  end,
})

local old_newImage = love.graphics.newImage
love.graphics.newImage = Memoize(function(...)
  local result = old_newImage(...)
  local args = {...}
  Ldump.serializer.handlers[result] = function()
    return love.graphics.newImage(unpack(args))
  end
  return result
end)

local old_newQuad = love.graphics.newQuad
love.graphics.newQuad = function(...)
  local result = old_newQuad(...)
  local args = {...}
  Ldump.serializer.handlers[result] = function()
    return love.graphics.newQuad(unpack(args))
  end
  return result
end

local old_newShader = love.graphics.newShader
love.graphics.newShader = function(...)
  local result = old_newShader(...)
  local args = {...}
  Ldump.serializer.handlers[result] = function()
    return love.graphics.newShader(unpack(args))
  end
  return result
end

local old_newFont = love.graphics.newFont
love.graphics.newFont = function(...)
  local result = old_newFont(...)
  local args = {...}
  Ldump.serializer.handlers[result] = function()
    return love.graphics.newFont(unpack(args))
  end
  return result
end

local old_newSpriteBatch = love.graphics.newSpriteBatch
love.graphics.newSpriteBatch = function(...)
  local result = old_newSpriteBatch(...)
  local args = {...}
  Ldump.serializer.handlers[result] = function()
    return love.graphics.newSpriteBatch(unpack(args))
  end
  return result
end

local old_newCanvas = love.graphics.newCanvas
love.graphics.newCanvas = function(...)
  local result = old_newCanvas(...)
  local args = {...}
  Ldump.serializer.handlers[result] = function()
    return love.graphics.newCanvas(unpack(args))
  end
  return result
end
