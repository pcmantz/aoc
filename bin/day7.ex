#!/usr/local/bin/elixir

defmodule Day7 do
  @moduledoc false

  defmodule Hand do
    defstruct [:cards_string, :bid]

    @cards ~w{J 2 3 4 5 6 7 8 9 T Q K A}
    @power @cards |> Enum.with_index |> Enum.into(%{})

    @types [:high, :pair, :two_pair, :three, :full_house, :four, :five]
    @type_map @types |> Enum.with_index |> Enum.into(%{})


    def sort_desc(left, right), do: sort_desc(right, left)

    def sort_asc(left, right) do
      left_chars = left.cards_string |> String.graphemes()
      right_chars = right.cards_string |> String.graphemes()

      left_groups = char_freq_map(left_chars)
      right_groups = char_freq_map(right_chars)

      left_highest_rank = highest_rank(left_groups)
      right_highest_rank = highest_rank(right_groups)

      cond do
        left_highest_rank != right_highest_rank ->
          left_highest_rank <= right_highest_rank

        left_highest_rank == 2 && right_highest_rank == 2 ->
          cond do
            is_two_pair?(left_groups) && is_two_pair?(right_groups) ->
              sort_asc_highest_hand(left_chars, right_chars)

            is_two_pair?(left_groups) ->
              false

            is_two_pair?(right_groups) ->
              true

            true ->
              sort_asc_highest_hand(left_chars, right_chars)
          end

        left_highest_rank == 3 && right_highest_rank == 3 ->
          cond do
            is_full_house?(left_groups) && is_full_house?(right_groups) ->
              sort_asc_highest_hand(left_chars, right_chars)

            is_full_house?(left_groups) ->
              false

            is_full_house?(right_groups) ->
              true

            true ->
              sort_asc_highest_hand(left_chars, right_chars)
          end

        left_highest_rank == right_highest_rank ->
          sort_asc_highest_hand(left_chars, right_chars)
      end
    end

    def highest_rank(groups) do
      case Enum.member?(groups, "J") do
        false -> simple_rank(groups)
        true -> groups["J"] + (groups |> Map.delete("J") |> simple_rank())
      end
    end

    def simple_rank(groups), do: groups |> Map.values() |> Enum.max()

    def char_freq_map(chars) do
      Enum.reduce(chars, %{}, fn char, acc ->
        Map.put(acc, char, (acc[char] || 0) + 1)
      end)
    end

    def is_two_pair?(groups) do
      Enum.sort(Map.values(groups), &(&1 <= &2)) == [1, 2, 2]
    end

    def is_full_house?(groups) do
      Enum.sort(Map.values(groups), &(&1 <= &2)) == [2, 3]
    end

    def sort_asc_highest_hand(left_list, right_list) do
      hand_power_list(left_list) <= hand_power_list(right_list)
    end

    def hand_power_list(list), do: list |> Enum.map(&@power[&1])
  end

  defmodule Parser do
    @moduledoc false

    def parse_file(filename) do
      filename
      |> File.stream!()
      |> Stream.map(&parse_line(&1))
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

# "tmp/day7_sample.txt" |> Day7.Parser.parse_file() |> Day7.score_hands_list()
