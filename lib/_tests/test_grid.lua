describe("Grid library", function()
  _G.unpack = table.unpack

  local grid = require("engine.lib.grid")
  local v = require("engine.lib.vector").new


  describe("grid.from_matrix()", function()
    it("should build a grid from matrix", function()
      local base_matrix = {
        {1, 2, 3},
        {4, 5, 6},
        {7, 8, 9},
      }
      assert.are_same(
        {1, 2, 3, 4, 5, 6, 7, 8, 9},
        grid.from_matrix(base_matrix, v(3, 3))._inner_array
      )
    end)
  end)

  describe("find_free_position", function()
    it("finds the closest nil", function()
      local this_grid = grid.from_matrix({
        {nil, nil, 111},
        {111, 111, 111},
        {111, 111, 111},
      }, v(3, 3))

      assert.are_equal(v(2, 1), this_grid:find_free_position(v(2, 2)))
    end)

    it("does not clash with grid borders", function()
      local this_grid = grid.from_matrix({
        {nil, nil, 111},
        {111, 111, 111},
        {111, 111, 111},
      }, v(3, 3))

      assert.are_equal(v(2, 1), this_grid:find_free_position(v(3, 3)))
    end)

    it("can accept max radius value", function()
      local this_grid = grid.from_matrix({
        {nil, nil, 111},
        {111, 111, 111},
        {111, 111, 111},
      }, v(3, 3))

      assert.are_equal(nil, this_grid:find_free_position(v(3, 3), 2))
    end)
  end)
end)
