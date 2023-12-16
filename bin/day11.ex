defmodule Day11 do
  defmodule Grid do
    defstruct [:tiles, :length, :width]

    def from_file(filename) do
      rows = filename |> File.stream!() |> Stream.map(&parse_line(&1))

      from_rows(rows)
    end

    def from_rows(rows) do
      tiles = rows |> Enum.map(&:array.from_list(&1)) |> :array.from_list()

      len = :array.size(tiles)
      wid = :array.get(0, tiles) |> then(&:array.size(&1))

      struct(Grid, %{tiles: tiles, length: len, width: wid})
    end

    defp parse_line(line) do
      line |> String.trim() |> String.graphemes()
    end

    def print(pipe_map) do
      for r <- 0..(pipe_map.length - 1) do
        for c <- 0..(pipe_map.width - 1) do
          IO.write(:stderr, do_get_tile(pipe_map.tiles, {r, c}))
        end

        IO.write(:stderr, "\n")
      end
    end

    def to_lists(grid) do
      grid.tiles
      |> array_to_list()
      |> Enum.map(&array_to_list/1)
    end

    def array_to_list(ary) do
      (:array.size(ary) - 1)..0
      |> Enum.reduce([], fn i, acc -> [:array.get(i, ary) | acc] end)
    end

    def get_tile(pipe_map, coords) do
      case valid_tile?(pipe_map, coords) do
        true -> do_get_tile(pipe_map.tiles, coords)
        _ -> nil
      end
    end

    defp do_get_tile(tiles, {r, c}) do
      row = :array.get(r, tiles)
      :array.get(c, row)
    end

    def all_coords(grid) do
      0..(grid.length - 1)
      |> Stream.flat_map(fn row ->
        0..(grid.width - 1) |> Stream.map(fn col -> {row, col} end)
      end)
    end

    def valid_tile?(_, nil), do: false

    def valid_tile?(%Grid{length: length, width: width}, {row, col}) do
      row >= 0 && row < length && col >= 0 && col < width
    end

    def matching_tiles(grid, ts) do
      all_coords(grid)
      |> Stream.map(fn coord -> {coord, do_get_tile(grid.tiles, coord)} end)
      |> Stream.filter(fn {_, tile} -> tile in ts end)
      |> Stream.map(&elem(&1, 0))
    end

    def distance(a, b) do
      abs(elem(a, 0) - elem(b, 0)) + abs(elem(a, 1) - elem(b, 1))
    end
  end

  defmodule Universe do
    defstruct [:grid, :galaxies, empty_rows: [], empty_cols: []]

    def from_grid(grid) do
      galaxies = Grid.matching_tiles(grid, ~w[#]) |> Enum.to_list()

      empty_rows = find_empty_rows(grid, galaxies)
      empty_cols = find_empty_cols(grid, galaxies)

      struct(Universe, %{
        grid: grid,
        galaxies: galaxies,
        empty_rows: empty_rows,
        empty_cols: empty_cols
      })
    end

    def expand!(universe) do
      new_width = universe.grid.width + Enum.count(universe.empty_cols)
      rows = Grid.to_lists(universe.grid)

      expanded_grid =
        rows
        |> Enum.map(&insert_empty_cols(&1, universe.empty_cols))
        |> insert_empty_rows(universe.empty_rows, new_width)
        |> Grid.from_rows()

      from_grid(expanded_grid)
    end

    # NOTE: Lists are reversed so they can be insert at-point without interfering with the
    # insertion of other elements.
    def find_empty_rows(grid, galaxies) do
      all_rows = MapSet.new(0..(grid.length - 1))
      galaxy_rows = galaxies |> Enum.map(&elem(&1, 0)) |> MapSet.new()

      MapSet.difference(all_rows, galaxy_rows) |> Enum.sort() |> Enum.reverse()
    end

    def find_empty_cols(grid, galaxies) do
      all_cols = MapSet.new(0..(grid.width - 1))
      galaxy_cols = galaxies |> Enum.map(&elem(&1, 1)) |> MapSet.new()

      MapSet.difference(all_cols, galaxy_cols) |> Enum.sort() |> Enum.reverse()
    end

    # NOTE: assumes empty_cols is in reverse order. see expand!
    def insert_empty_cols(row, empty_cols) do
      empty_cols |> Enum.reduce(row, &List.insert_at(&2, &1, "."))
    end

    # NOTE: assumes empty_rows is in reverse order. see expand!
    def insert_empty_rows(rows, empty_rows, new_width) do
      empty_rows |> Enum.reduce(rows, &List.insert_at(&2, &1, List.duplicate(".", new_width)))
    end

    def old_universe_distance(universe, a, b) do
      dist = Grid.distance(a, b)

      empty_row_crosses =
        universe.empty_rows |> Enum.filter(&between(elem(a, 0), elem(b, 0), &1)) |> Enum.count()

      empty_col_crosses =
        universe.empty_cols |> Enum.filter(&between(elem(a, 1), elem(b, 1), &1)) |> Enum.count()

      dist + (empty_row_crosses + empty_col_crosses) * 999_999
    end

    # NOTE: we know that x will never equal a or b because
    def between(a, b, x) do
      (a <= x && x <= b) || (b <= x && x <= a)
    end

    def comb2(n) do
      1..(n - 1)
      |> Enum.flat_map(fn from ->
        (from + 1)..n |> Enum.map(fn to -> {from, to} end)
      end)
    end

    def build_galaxy_map(universe) do
      universe.galaxies
      |> Enum.with_index(1)
      |> Enum.map(&%{elem(&1, 1) => elem(&1, 0)})
      |> Enum.reduce(%{}, &Enum.into(&2, &1))
    end
  end

  def part1(filename) do
    universe =
      filename
      |> Grid.from_file()
      |> Universe.from_grid()

    expanded_universe = Universe.expand!(universe)

    galaxy_map = Universe.build_galaxy_map(expanded_universe)

    pairs = expanded_universe.galaxies |> Enum.count() |> Universe.comb2()

    pairs
    |> Enum.map(fn {from, to} -> Grid.distance(galaxy_map[from], galaxy_map[to]) end)
    |> Enum.sum()
  end

  def part2(filename) do
    universe = filename |> Grid.from_file() |> Universe.from_grid()

    pairs = universe.galaxies |> Enum.count() |> Universe.comb2()
    galaxy_map = Universe.build_galaxy_map(universe)

    pairs
    |> Enum.map(fn {from, to} ->
      Universe.old_universe_distance(universe, galaxy_map[from], galaxy_map[to])
    end)
    |> Enum.sum()
  end
end
