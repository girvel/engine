local ffi = require("ffi")
local ffi_fix = require("engine.tech.ffi_fix")


-- Rewrite:
-- orient on multiple visions

local tcod = {}

ffi.cdef([[
  typedef enum {
    FOV_BASIC,
    FOV_DIAMOND,
    FOV_SHADOW,
    FOV_PERMISSIVE_0,FOV_PERMISSIVE_1,FOV_PERMISSIVE_2,FOV_PERMISSIVE_3,
    FOV_PERMISSIVE_4,FOV_PERMISSIVE_5,FOV_PERMISSIVE_6,FOV_PERMISSIVE_7,FOV_PERMISSIVE_8,
    FOV_RESTRICTIVE,
    NB_FOV_ALGORITHMS
  } TCOD_fov_algorithm_t;

  struct TCOD_Map *TCOD_map_new(int width, int height);
  void TCOD_map_clear(struct TCOD_Map *map, bool transparent, bool walkable);
  void TCOD_map_copy(struct TCOD_Map *source, struct TCOD_Map *dest);
  void TCOD_map_delete(struct TCOD_Map *map);

  void TCOD_map_set_properties(
    struct TCOD_Map *map, int x, int y, bool is_transparent, bool is_walkable
  );

  void TCOD_map_compute_fov(
    struct TCOD_Map *map, int player_x, int player_y, int max_radius, bool light_walls,
    TCOD_fov_algorithm_t algo
  );

  bool TCOD_map_is_transparent(struct TCOD_Map *map, int x, int y);
  bool TCOD_map_is_walkable(struct TCOD_Map *map, int x, int y);
  bool TCOD_map_is_in_fov(struct TCOD_Map *map, int x, int y);

  // struct TCOD_Dijkstra *TCOD_dijkstra_new(struct TCOD_Map *map, float diagonalCost);
  // void TCOD_dijkstra_delete(TCOD_Dijkstra *dijkstra);

  struct TCOD_Path *TCOD_path_new_using_map(struct TCOD_Map *map, float diagonalCost);
  void TCOD_path_delete(struct TCOD_Path *path);

  bool TCOD_path_compute(struct TCOD_Path *path, int ox, int oy, int dx, int dy);
  int TCOD_path_size(struct TCOD_Path *path);
  void TCOD_path_get(struct TCOD_Path *path, int index, int *x, int *y);
]])

local tcod_c = ffi_fix.load("libtcod")


--- @class snapshot
--- @field _map any
--- @field _grid grid
--- @field r integer
--- @field px integer
--- @field py integer
local snapshot_methods = {}

tcod.ok = not not tcod_c

if tcod_c then
  --- To be called on empty grid
  --- @generic T
  --- @param grid T
  --- @return T
  tcod.observer = function(grid)
    --- @cast grid grid
    local w, h = unpack(grid.size)
    local map = tcod_c.TCOD_map_new(w, h)
    for x = 1, w do
      for y = 1, h do
        local e = grid:unsafe_get(x, y)
        tcod_c.TCOD_map_set_properties(
          map, x - 1, y - 1, not e or not not e.transparent_flag, not e
        )
      end
    end
    local snapshot = setmetatable({_grid = grid, _map = map}, {__index = snapshot_methods})
    return setmetatable({
      _tcod__snapshot = snapshot,
    }, {
      __index = grid,

      __newindex = function(self, index, value)
        grid[index] = value
        local x, y = unpack(index)
        tcod_c.TCOD_map_set_properties(
          rawget(self, "_tcod__snapshot")._map,
          x - 1, y - 1,
          not value or not not value.transparent_flag, not value
        )
      end,

      __serialize = function(self)
        local grid_copy = rawget(self, "_tcod__snapshot")._grid
        return function()
          return tcod.observer(grid_copy)
        end
      end,
    })
  end

  --- @param wrapped_grid grid Actually, not grid but a tcod.observer
  --- @return snapshot
  tcod.snapshot = function(wrapped_grid)
    return rawget(wrapped_grid, "_tcod__snapshot")
  end

  --- @param wrapped_grid grid Actually, not grid but a tcod.observer
  --- @return snapshot
  tcod.copy = function(wrapped_grid)
    local inner = rawget(wrapped_grid, "_tcod__snapshot")
    local w, h = unpack(inner._grid.size)
    local map = tcod_c.TCOD_map_new(w, h)
    tcod_c.TCOD_map_copy(inner._map, map)
    return setmetatable({_map = map}, {
      __index = snapshot_methods,
    })
  end

  --- For some reason even manually triggered __gc doesn't work
  snapshot_methods.free = function(self)
    tcod_c.TCOD_map_delete(self._map)
    self._map = nil
  end

  --- @return nil
  snapshot_methods.refresh_fov = function(self, position, r)
    local px, py = unpack(position)
    tcod_c.TCOD_map_compute_fov(
      self._map, px - 1, py - 1, r, true, tcod_c.FOV_PERMISSIVE_8
    )
  end

  --- @param x integer
  --- @param y integer
  --- @return boolean
  snapshot_methods.is_visible_unsafe = function(self, x, y)
    return tcod_c.TCOD_map_is_in_fov(self._map, x - 1, y - 1)
  end

  --- @param x integer
  --- @param y integer
  --- @return boolean
  snapshot_methods.is_transparent_unsafe = function(self, x, y)
    return tcod_c.TCOD_map_is_transparent(self._map, x - 1, y - 1)
  end

  --- @param origin vector
  --- @param destination vector
  --- @return vector[]
  snapshot_methods.find_path = function(self, origin, destination)
    assert(
      self._grid:can_fit(origin),
      ("find_path origin %s is out of grid borders"):format(origin)
    )
    assert(
      self._grid:can_fit(destination),
      ("find_path destination %s is out of grid borders"):format(destination)
    )

    local raw_path = tcod_c.TCOD_path_new_using_map(self._map, 0)
    local ox, oy = unpack(origin - Vector.one)
    local dx, dy = unpack(destination - Vector.one)
    tcod_c.TCOD_path_compute(raw_path, ox, oy, dx, dy)

    local result = {}
    for i = 0, tcod_c.TCOD_path_size(raw_path) - 1 do
      local xp = ffi.new("int[1]")
      local yp = ffi.new("int[1]")
      tcod_c.TCOD_path_get(raw_path, i, xp, yp)
      table.insert(result, V(xp[0], yp[0]) + Vector.one)
    end
    tcod_c.TCOD_path_delete(raw_path)

    return result
  end

else
  Log.error("Unable to locate libtcod library")

  tcod.observer = function(grid)
    return grid
  end

  tcod.snapshot = function(wrapped_grid)
    return setmetatable({_grid = wrapped_grid}, {__index = snapshot_methods})
  end

  tcod.copy = function(wrapped_grid)
    return setmetatable({_grid = wrapped_grid}, {__index = snapshot_methods})
  end

  snapshot_methods.refresh_fov = function(self, position, r)
    self.r = math.floor(r * 2 / 3)
    self.px, self.py = unpack(position)
  end

  snapshot_methods.is_visible_unsafe = function(self, x, y)
    return math.abs(self.px - x) <= self.r and math.abs(self.py - y) <= self.r
  end

  snapshot_methods.is_transparent_unsafe = function(self, x, y)
    local e = self._grid:unsafe_get(x, y)
    return not e or (not not e.transparent_flag)
  end

  snapshot_methods.find_path = function(self, origin, destination)
    return {}
  end
end

Ldump.mark(tcod, {}, ...)
return tcod
