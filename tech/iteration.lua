local iteration = {}

--- @param radius? integer
--- @return fun(): vector
iteration.expanding_rhombus = function(radius)
  return coroutine.wrap(function()
    coroutine.yield(Vector.zero)

    for r = 1, radius or 100 do
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

Ldump.mark(iteration, {}, ...)
return iteration
