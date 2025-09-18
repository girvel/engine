local iteration = {}

--- Guarantees that returned vectors are not references anywhere else
--- @param radius? integer
--- @param step? integer (default 1)
--- @return fun(): vector
iteration.rhombus = function(radius, step)
  return coroutine.wrap(function()
    coroutine.yield(Vector.zero:copy())

    step = step or 1
    radius = radius or 100
    local a, b if step > 0 then
      a = 1
      b = radius
    else
      assert(step ~= 0)
      a = radius
      b = 1
    end

    for r = a, b, step do
      for x = 0, r - 1 do
        coroutine.yield(V(x, x - r))
      end

      for x = r, 1, -1 do
        coroutine.yield(V(x, r - x))
      end

      for x = 0, 1 - r, -1 do
        coroutine.yield(V(x, x + r))
      end

      for x = -r, 1 do
        coroutine.yield(V(x, -r - x))
      end
    end
  end)
end

--- Guarantees that returned vectors are not references anywhere else
--- @param radius? integer
--- @return fun(): vector
iteration.rhombus_edge = function(radius)
  return coroutine.wrap(function()
    for x = 0, radius - 1 do
      coroutine.yield(V(x, x - radius))
    end

    for x = radius, 1, -1 do
      coroutine.yield(V(x, radius - x))
    end

    for x = 0, 1 - radius, -1 do
      coroutine.yield(V(x, x + radius))
    end

    for x = -radius, 1 do
      coroutine.yield(V(x, -radius - x))
    end
  end)
end

Ldump.mark(iteration, {}, ...)
return iteration
