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

  describe("find_path", function()
    it("should find paths", function()
      local this_grid = grid.from_matrix({
        {nil, nil, nil},
        {nil, 1,   nil},
        {nil, nil, nil},
      }, v(3, 3))

      assert.are_same(
        {v(1, 1), v(2, 1), v(3, 1)},
        this_grid:find_path(v(1, 2), v(3, 1))
      )
    end)

    it("should work with start & end occupied", function()
      local this_grid = grid.from_matrix({
        {nil, nil, 1  },
        {1,   1,   nil},
        {nil, nil, nil},
      }, v(3, 3))

      assert.are_same(
        {v(1, 1), v(2, 1), v(3, 1)},
        this_grid:find_path(v(1, 2), v(3, 1))
      )
    end)

    it("should find the next best thing if there is no full path", function()
      local this_grid = grid.from_matrix({
        {1,   1,   1  },
        {1,   1,   1  },
        {nil, nil, nil},
      }, v(3, 3))

      assert.are_same(
        {v(2, 3), v(3, 3)},
        this_grid:find_path(v(1, 3), v(3, 1))
      )
    end)

    it("should work with distance limit", function()
      local this_grid = grid.from_matrix({
        {nil, nil, nil, nil, nil},
      }, v(5, 1))
      local max_distance = 3
      local path = this_grid:find_path(v(1, 1), v(5, 1), max_distance)
      assert.is_true(#path >= max_distance)
      assert.is_true(#path < this_grid.size[1])
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
