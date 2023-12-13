#!/usr/local/bin/elixir

defmodule Day9 do
  def add_next_number(sequence) do
    {start, differences} = find_start_and_differences(sequence)

    cond do
      # NOTE: Because we are dealing with lists instead of array elements, it does not matter
      # whether we add a 0 to the beginning or end. The real crucial difference is what function we
      # use to apply the list.
      Enum.all?(differences, &(&1 == 0)) -> apply_differences(start, [0] ++ differences)
      true -> apply_differences(start, add_next_number(differences))
    end
  end

  def prepend_number(sequence) do
    {start, differences} = find_start_and_differences(sequence)

    cond do
      Enum.all?(differences, &(&1 == 0)) -> apply_prepend_differences(start, [0] ++ differences )
      true -> apply_prepend_differences(start, prepend_number(differences))
    end
  end

  def find_start_and_differences(sequence) do
    start = List.first(sequence)

    differences =
      sequence
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [first, next] -> next - first end)

    {start, differences}
  end

  def apply_differences(start, differences) do
    [start] ++ Enum.scan(differences, start, &(&1 + &2))
  end

  def apply_prepend_differences(start, differences) do
    [first_diff | rest_diff] = differences
    [start - first_diff] ++ apply_differences(start, rest_diff)
  end

  defmodule Parser do
    def parse_file(filename) do
      filename |> File.stream!() |> Stream.map(&parse_line(&1)) |> Enum.to_list()
    end

    def parse_line(line) do
      line |> String.trim() |> String.split() |> Enum.map(&string_to_integer/1)
    end

    def string_to_integer(str), do: str |> String.trim() |> Integer.parse() |> elem(0)
  end

  def part1(filename) do
    added_sequences =
      filename
      |> Parser.parse_file()
      |> Enum.map(&add_next_number/1)

    added_sequences |> Enum.map(&List.last/1) |> Enum.sum()
  end

  def part2(filename) do
    added_sequences =
      filename
      |> Parser.parse_file()
      |> Enum.map(&prepend_number/1)

    added_sequences |> Enum.map(&List.first/1) |> Enum.sum()
  end
end
