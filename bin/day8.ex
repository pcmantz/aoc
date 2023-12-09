#!/usr/local/bin/elixir

defmodule Day8 do
  defmodule Network do
    defstruct [:pattern, :node_map]

    def start_keys(network) do
      Map.keys(network.node_map) |> Enum.filter(&Regex.match?(~r/..A/, &1))
    end

    def finish_keys(network) do
      Map.keys(network.node_map) |> Enum.filter(&Regex.match?(~r/..Z/, &1))
    end

    def steps_between_nodes(network, start, finishes) do
      start_place = {"X", 0, start}

      final_step =
        network.pattern
        |> Stream.cycle()
        |> Stream.with_index(1)
        |> Stream.transform(start_place, &next_place_flat_map(&1, &2, network))
        |> Stream.filter(fn {_, _, node} -> node in finishes end)
        |> Enum.take(1)
        |> List.first

      elem(final_step, 1)
    end

    def next_place_flat_map(step_pair, current_place, network) do
      next_place = next_place(step_pair, current_place, network)

      {[next_place], next_place}
    end

    def next_place(step_pair, current_place, network) do
      {direction, step} = step_pair
      {_, _, current_node} = current_place

      edges = Map.get(network.node_map, current_node)

      next_node =
        case direction do
          "L" -> elem(edges, 0)
          "R" -> elem(edges, 1)
        end

      # IO.puts("Step #{step}: #{current_node} -> #{next_node}")

      {direction, step, next_node}
    end
  end

  defmodule Parser do
    @node_line_regex ~r/(?<node>\w+)\s+=\s+\((?<left>\w+),\s+(?<right>\w+)\)/

    def parse_file(filename) do
      {:ok, fh} = File.open(filename)
      direction_line = IO.read(fh, :line)
      pattern = direction_line |> String.trim() |> String.graphemes()

      node_map =
        parse_nodes(fh)
        |> then(fn x -> Enum.reduce(x, fn map, acc -> Map.merge(acc, map) end) end)

      struct(Network, pattern: pattern, node_map: node_map)
    end

    def parse_nodes(fh) do
      IO.stream(fh, :line)
      |> Stream.filter(&Regex.match?(~r/\w+/, &1))
      |> Stream.map(&parse_node_line(&1))
      |> Enum.to_list()
    end

    def parse_node_line(line) do
      [_, node, left, right] = line |> String.trim() |> then(&Regex.run(@node_line_regex, &1))

      %{node => {left, right}}
    end
  end

  def part1(filename) do
    network = Parser.parse_file(filename)

    Network.steps_between_nodes(network, "AAA", ["ZZZ"])
  end

  def part2(filename) do
    network = Parser.parse_file(filename)

    starts = Network.start_keys(network)
    finishes = Network.finish_keys(network)

    path_lengths = Enum.map(starts, &Network.steps_between_nodes(network, &1, finishes))

    Enum.reduce(path_lengths, &( trunc(&1 * &2 / Integer.gcd(&1, &2)) ))
  end
end
