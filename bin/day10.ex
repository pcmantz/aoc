#!/usr/local/bin/elixir

require IEx

defmodule Day10 do
  defmodule PipeMap do
    defstruct [:tiles, :start, :length, :width]

    def distance_map(pipe_map), do: distance_map(pipe_map, [pipe_map.start], 0, %{})

    def distance_map(_, [], _, distance_map), do: distance_map

    def distance_map(pipe_map, queue, distance, distance_map) do
      distance_map(
        pipe_map,
        adjacent_coords(pipe_map, queue, distance, distance_map),
        distance + 1,
        queue |> Enum.map(&{&1, distance}) |> Enum.into(distance_map)
      )
    end

    def adjacent_coords(pipe_map, coords, _, distance_map) do
      coords
      |> Enum.flat_map(&adjacent_coords(pipe_map, &1))
      |> Enum.uniq()
      |> Enum.filter(&(!Map.has_key?(distance_map, &1)))
    end

    def adjacent_coords(pipe_map, coord) do
      tile = get_tile(pipe_map, coord)

      do_adjacent_coords(pipe_map, coord, tile)
    end

    # NOTE: This should never happen
    def do_adjacent_coords(_, _, "."), do: []

    def do_adjacent_coords(pipe_map, coord, tile) do
      {row, col} = coord

      [
        above_coord(tile, get_tile(pipe_map, {row - 1, col}), {row - 1, col}),
        right_coord(tile, get_tile(pipe_map, {row, col + 1}), {row, col + 1}),
        left_coord(tile, get_tile(pipe_map, {row, col - 1}), {row, col - 1}),
        below_coord(tile, get_tile(pipe_map, {row + 1, col}), {row + 1, col})
      ]
      |> Enum.filter(&valid_tile?(pipe_map, &1))
    end

    def above_coord("S", t, coord) when t in ~w[| 7 F], do: coord
    def above_coord("J", t, coord) when t in ~w[| 7 F], do: coord
    def above_coord("L", t, coord) when t in ~w[| 7 F], do: coord
    def above_coord("|", t, coord) when t in ~w[| 7 F], do: coord
    def above_coord(_, _, _), do: nil

    def below_coord("S", t, coord) when t in ~w[J | L], do: coord
    def below_coord("7", t, coord) when t in ~w[J | L], do: coord
    def below_coord("F", t, coord) when t in ~w[J | L], do: coord
    def below_coord("|", t, coord) when t in ~w[J | L], do: coord
    def below_coord(_, _, _), do: nil

    def left_coord("S", t, coord) when t in ~w[- F L], do: coord
    def left_coord("-", t, coord) when t in ~w[- F L], do: coord
    def left_coord("7", t, coord) when t in ~w[- F L], do: coord
    def left_coord("J", t, coord) when t in ~w[- F L], do: coord
    def left_coord(_, _, _), do: nil

    def right_coord("S", t, coord) when t in ~w[- 7 J], do: coord
    def right_coord("-", t, coord) when t in ~w[- 7 J], do: coord
    def right_coord("F", t, coord) when t in ~w[- 7 J], do: coord
    def right_coord("L", t, coord) when t in ~w[- 7 J], do: coord
    def right_coord(_, _, _), do: nil

    def get_tile(pipe_map, coords) do
      case valid_tile?(pipe_map, coords) do
        true -> do_get_tile(pipe_map.tiles, coords)
        _ -> nil
      end
    end

    def do_get_tile(tiles, {r, c}) do
      row = :array.get(r, tiles)
      :array.get(c, row)
    end

    def valid_tile?(_, nil), do: false

    def valid_tile?(%PipeMap{length: length, width: width}, {row, col}) do
      row >= 0 && row < length && col >= 0 && col < width
    end

    def clean_pipe_map(pipe_map) do
      distance_map = distance_map(pipe_map)
      new_tiles = :array.new(pipe_map.length)

      populated_tiles =
        0..(pipe_map.length - 1)
        |> Enum.reduce(new_tiles, fn r, acc ->
          new_row = clean_pipe_map_new_row(pipe_map, distance_map, r)
          :array.set(r, new_row, acc)
        end)

      struct(PipeMap, %{
        tiles: populated_tiles,
        start: pipe_map.start,
        length: pipe_map.length,
        width: pipe_map.width
      })
    end

    def clean_pipe_map_new_row(pipe_map, distance_map, r) do
      new_row = :array.new(pipe_map.width)

      populated_row =
        0..(pipe_map.width - 1)
        |> Enum.reduce(new_row, fn c, acc ->
          new_tile = clean_pipe_map_new_tile(pipe_map, distance_map, r, c)
          :array.set(c, new_tile, acc)
        end)

      populated_row
    end

    def clean_pipe_map_new_tile(pipe_map, distance_map, r, c) do
      tile = get_tile(pipe_map, {r, c})
      distance = distance_map[{r, c}]

      case {tile, distance} do
        {".", _} -> "."
        {_, nil} -> "."
        {_, _} -> tile
      end
    end

    def all_coords(pipe_map) do
      0..(pipe_map.length - 1)
      |> Stream.flat_map(fn row ->
        0..(pipe_map.width - 1) |> Stream.map(fn col -> {row, col} end)
      end)
    end

    def count_inside_tiles(pipe_map) do
      0..(pipe_map.length - 1)
      |> Enum.map(fn r -> :array.get(r, pipe_map.tiles) |> inside_tiles() end)
      |> Enum.sum
    end

    def inside_tiles(row) do
      inside_tiles_acc(:array.to_list(row), 0, 0)
    end

    def inside_tiles_acc([], _, insides), do: insides

    def inside_tiles_acc([first | rest], crossings, insides) do
      case {first, rem(crossings, 2)} do
        {p, _} when p in ~w[|] -> inside_tiles_acc(rest, crossings + 1, insides)
        {p, _} when p in ~w[F] -> inside_tiles_acc_coming_up(rest, crossings, insides)
        {p, _} when p in ~w[L S] -> inside_tiles_acc_coming_down(rest, crossings, insides)
        {".", 0} -> inside_tiles_acc(rest, crossings, insides)
        {".", 1} -> inside_tiles_acc(rest, crossings, insides + 1)
        {p, c} -> raise "unexpected map tile '#{p}' with mod crossing #{c}, rest of line: #{rest}"
      end
    end

    def inside_tiles_acc_coming_up([], _, insides), do: insides

    def inside_tiles_acc_coming_up([first | rest], crossings, insides) do
      case {first, rem(crossings, 2)} do
        {p, _} when p in ~w[-] -> inside_tiles_acc_coming_up(rest, crossings, insides)
        {p, _} when p in ~w[J] -> inside_tiles_acc(rest, crossings + 1, insides)
        {p, _} when p in ~w[7] -> inside_tiles_acc(rest, crossings, insides)
        {p, c} -> raise "unexpected map tile '#{p}' with mod crossing #{c}, rest of line: #{rest}"
      end
    end

    def inside_tiles_acc_coming_down([], _, insides), do: insides

    def inside_tiles_acc_coming_down([first | rest], crossings, insides) do
      case {first, rem(crossings, 2)} do
        {p, _} when p in ~w[-] -> inside_tiles_acc_coming_down(rest, crossings, insides)
        {p, _} when p in ~w[J] -> inside_tiles_acc(rest, crossings, insides)
        {p, _} when p in ~w[7] -> inside_tiles_acc(rest, crossings + 1, insides)
        {p, c} -> raise "unexpected map tile '#{p}' with mod crossing #{c}, rest of line: #{rest}"
      end
    end

    def print(pipe_map) do
      for r <- 0..(pipe_map.length - 1) do
        for c <- 0..(pipe_map.width - 1) do
          IO.write(:stderr, do_get_tile(pipe_map.tiles, {r, c}))
        end

        IO.write(:stderr, "\n")
      end
    end
  end

  defmodule Parser do
    def parse_file(filename) do
      rows = filename |> File.stream!() |> Stream.map(&parse_line(&1))

      # NOTE: Make an array of an arrays here. Consider using nx in the future.
      tiles = rows |> Enum.map(&:array.from_list(&1)) |> :array.from_list()

      len = :array.size(tiles)
      wid = tiles |> then(&:array.get(0, &1)) |> :array.size()

      start = find_start(tiles, len, wid)

      struct(PipeMap, %{tiles: tiles, start: start, length: len, width: wid})
    end

    def parse_line(line) do
      line |> String.trim() |> String.graphemes()
    end

    def find_start(tiles, len, wid) do
      coords =
        0..(len - 1)
        |> Stream.flat_map(fn row -> 0..(wid - 1) |> Stream.map(fn col -> {row, col} end) end)

      Enum.find(coords, fn {row, col} -> PipeMap.do_get_tile(tiles, {row, col}) == "S" end)
    end
  end

  def part1(filename) do
    pipe_map = Parser.parse_file(filename)

    distance_map = PipeMap.distance_map(pipe_map)

    distance_map |> Map.values() |> Enum.max()
  end

  def part2(filename) do
    pipe_map = Parser.parse_file(filename)

    cleaned_pipe_map = PipeMap.clean_pipe_map(pipe_map)

    PipeMap.count_inside_tiles(cleaned_pipe_map)
  end

  def print_cleaned_map(filename) do
    pipe_map = Parser.parse_file(filename)

    cleaned_pipe_map = PipeMap.clean_pipe_map(pipe_map)
    PipeMap.print(cleaned_pipe_map)
  end
end
