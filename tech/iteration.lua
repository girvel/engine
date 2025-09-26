local iteration = {}

--- Guarantees that returned vectors are not references anywhere else
--- @return fun(): vector
iteration.rhombus = function(a, b, c)
  return coroutine.wrap(function()
    coroutine.yield(Vector.zero:copy())

    if not c then
      if not b then
        if not a then
          a = 100
        end
        b = a
        a = 1
        c = 1
      else
        c = Math.sign(b - a)
      end
    end

    for r = a, b, c do
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
