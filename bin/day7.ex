#!/usr/local/bin/elixir

defmodule Day7 do
  @moduledoc """
  Day7: Module for solving Day & of Advent of Code

  This is currently configure to present a solution to the second part. In order to solve the first
  part with this script, rearrange @cards to put J after T, and eliminate the `counts_for_groups`
  method that handles when J is a key.
  """

  defmodule Hand do
    defstruct [:cards_string, :bid]

    @cards ~w{J 2 3 4 5 6 7 8 9 T Q K A}
    @power @cards |> Enum.with_index() |> Enum.into(%{})

    @types [:high, :pair, :two_pair, :three, :full_house, :four, :five]
    @type_map @types |> Enum.with_index() |> Enum.into(%{})

    def sort_desc(left, right), do: sort_desc(right, left)

    def type(hand), do: hand.cards_string |> char_freq_map |> counts_for_groups |> type_for_counts
    def type_value(hand), do: @type_map[type(hand)]

    def power_list(hand), do: hand.cards_string |> String.graphemes() |> Enum.map(&@power[&1])

    def sort_asc(left, right) do
      left_type = type_value(left)
      right_type = type_value(right)

      cond do
        left_type < right_type -> true
        left_type > right_type -> false
        left_type == right_type -> power_list(left) <= power_list(right)
      end
    end

    def type_for_counts(counts) do
      case counts do
        [5] -> :five
        [4, 1] -> :four
        [3, 2] -> :full_house
        [3, 1, 1] -> :three
        [2, 2, 1] -> :two_pair
        [2, 1, 1, 1] -> :pair
        [1, 1, 1, 1, 1] -> :high
      end
    end

    def char_freq_map(string), do: string |> String.graphemes() |> Enum.frequencies()

    defp counts_for_groups(groups) when is_map_key(groups, "J") do
      case groups["J"] do
        5 ->
          [5]

        4 ->
          [5]

        joker_count = _ ->
          base_count = groups |> Map.delete("J") |> counts_for_groups
          head_count = List.first(base_count) + joker_count

          List.replace_at(base_count, 0, head_count)
      end
    end

    defp counts_for_groups(groups), do: groups |> Map.values() |> Enum.sort(&(&1 >= &2))
  end

  defmodule Parser do
    @moduledoc false

    def parse_file(filename) do
      filename |> File.stream!() |> Stream.map(&parse_line(&1))
    end

    def parse_line(line) do
      [cards_string, bid] = line |> String.split(~r/\s+/, trim: true)

      struct(Hand, %{cards_string: cards_string, bid: string_to_integer(bid)})
    end

    def string_to_integer(str), do: str |> String.trim() |> Integer.parse() |> elem(0)
  end

  def score_hands_list(hands) do
    hands
    |> Enum.sort(&Hand.sort_asc(&1, &2))
    |> Enum.with_index(1)
    |> Enum.map(&score_hand/1)
    |> Enum.sum()
  end

  def score_hand({hand, rank}), do: rank * hand.bid
end

"tmp/day7_sample.txt" |> Day7.Parser.parse_file() |> Day7.score_hands_list()
