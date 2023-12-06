#!/usr/local/bin/elixir

defmodule Day4 do
  @moduledoc false

  defmodule Card do
    defstruct [:id, :winning, :numbers]

    def matches(card) do
      [card.winning, card.numbers]
      |> Enum.map(&MapSet.new(&1))
      |> Enum.reduce(&MapSet.intersection/2)
      |> Enum.count()
    end

    def points(card) do
      matches = matches(card)

      if matches == 0, do: 0, else: 2 ** (matches - 1)
    end
  end

  defmodule Batch do
    defstruct [:cards]

    def cards_won(batch) do
      cards_won_map(batch) |> Map.values() |> Enum.sum()
    end

    def cards_won_map(batch) do
      card_count_map =
        batch.cards
        |> Enum.reduce(%{}, &Map.put(&2, &1.id, 1))

      batch.cards
      |> Enum.reduce(card_count_map, &win_cards(&1, &2, Enum.count(batch.cards)))
    end

    defp win_cards(current_card, card_count_map, max_card_id) do
      matches = Card.matches(current_card)

      add_won_cards(current_card, card_count_map, matches, max_card_id)
    end

    def add_won_cards(_, card_count_map, 0, _), do: card_count_map

    def add_won_cards(current_card, card_count_map, matches, max_card_id) when matches >= 1 do
      current_card_count = card_count_map[current_card.id]

      won_cards_start = current_card.id + 1
      won_cards_end = [current_card.id + matches, max_card_id] |> Enum.min()

      won_cards_map =
        won_cards_start..won_cards_end
        |> Enum.reduce(%{}, &Map.put(&2, &1, current_card_count))

      Map.merge(card_count_map, won_cards_map, fn _k, v1, v2 -> v1 + v2 end)
    end
  end

  defmodule Parser do
    @line_regex ~r/^Card\s+(\d+):([^|]+)\|([^|]+)$/

    def parse_file(filename) do
      filename
      |> File.stream!()
      |> Stream.map(&parse_line(&1))
    end

    def parse_line(line) do
      [_, id_string, winning_string, numbers_string] = Regex.run(@line_regex, line)

      {id, _} = Integer.parse(id_string)
      winning = parse_number_string(winning_string)
      numbers = parse_number_string(numbers_string)

      struct(Card, %{id: id, winning: winning, numbers: numbers})
    end

    def parse_number_string(number_string) do
      strings =
        number_string
        |> String.trim()
        |> String.split(~r/\s+/)

      Enum.map(strings, &string_to_integer(&1))
    end

    def string_to_integer(str) do
      str |> String.trim() |> Integer.parse() |> elem(0)
    end
  end

  def total_points(filename) do
    cards_stream = Parser.parse_file(filename)

    cards_stream |> Stream.map(&Card.points(&1)) |> Enum.sum()
  end

  def cards_won(filename) do
    cards_stream = Parser.parse_file(filename)

    struct(Batch, %{cards: cards_stream}) |> Batch.cards_won()
  end
end
