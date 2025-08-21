describe("composite map", function()
  local composite_map = require("engine.lib.composite_map")

  it("is indexed by composite keys", function()
    local map = composite_map.new()
    map:set(69, "hi", 3)
    assert.are_equal(69, map:get("hi", 3))
  end)

  it("has no conflict between branches and leaves", function()
    local map = composite_map.new()
    map:set(69, "hi", 3)
    map:set(42, "hi")
    map:set(1337, 3)
    assert.are_equal(69, map:get("hi", 3))
    assert.are_equal(42, map:get("hi"))
    assert.are_equal(1337, map:get(3))
  end)

  it("is iterable", function()
    local map = composite_map.new()
    map:set(69, "hi", 3)
    map:set(42, "hi")
    map:set(1337, 3)

    local keys = {[69] = {"hi", 3}, [42] = {"hi"}, [1337] = {3}}
    for k, v in map:iter() do
      assert.are_same(keys[v], k)
      keys[v] = nil
    end

    assert.are_equal(nil, keys[69])
    assert.are_equal(nil, keys[42])
    assert.are_equal(nil, keys[1337])
  end)
end)
