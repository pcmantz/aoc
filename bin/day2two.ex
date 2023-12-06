#!/usr/local/bin/elixir

# Incomplete translation of the ruby version.
#
#
defmodule Day2Two do
  @moduledoc false

  defmodule Round do
    defstruct [red: 0, green: 0, blue: 0]

    def max_color(rounds, color) do
      Enum.max(rounds |> Enum.map(&( &1[color] )))
    end
  end

  defmodule Round do
    defstruct [red: 0, green: 0, blue: 0]

    def max_color(rounds, color) do
      Enum.max(rounds |> Enum.map(&( &1[color] )))
    end
  end

  defmodule Game do
    defstruct [:id, :rounds]

    def game_possible?(game) do
      Enum.all?(
        game.rounds,
        fn (round) -> round.red <= 12 && round.green <= 13 && round.blue <= 14 end
      )
    end

    def fewest_bag(game) do
      struct(
        Bag,
        %{
          red: Round.max_color(game.rounds, :red),
          green: Round.max_color(game.rounds, :green),
          blue: Round.max_color(game.round, :blue)
        }
      )
    end
  end

  def run(filename) do
    games = games_from_file(filename)
    possible_games = Enum.filter(games, &( Game.possible?(&1) ))

    total_game_power = possible_games
    |> Enum.map(&( Game.fewest_bag(&1) ))
    |> Enum.map(&( Bag.power(&1) ))
    |> Enum.sum

  end

  def game_possible?(game) do
    Enum.all?(
      game.rounds,
      fn (round) -> round.red <= 12 && round.green <= 13 && round.blue <= 14 end
    )

  end

  def games_from_file(filename) do
    File.stream!(filename) |> Stream.map(&( parse_line(&1) ))
  end


  def parse_line(line) do
    [game_line, rounds_line] = line |> String.split(":", trim: true)

    game_id = parse_game_line(game_line)

    rounds_strings = rounds_line |> String.split(";") |> Enum.map(&( String.trim(&1) ))
    rounds = Enum.map(rounds_strings, &( parse_round_line(&1) ))

    struct(Game, id: game_id, rounds: rounds)
  end

  def parse_game_line(<<"Game ", number::binary>>), do: to_integer(number)

  def parse_round_line(round_line) do
    args = round_line
    |> String.split(",")
    |> Enum.map(&( String.trim(&1) ))
    |> Enum.map(&parse_cube_line/1)
    |> Enum.reduce(&Map.merge/2)

    struct(Round, args)
  end

  def parse_cube_line(cube_line) do
    vals = Regex.named_captures(~r{^(?<count>\d+)\s+(?<color>\w+)$}, cube_line)

    {count, _} = vals["count"] |> Integer.parse
    color =  case vals["color"] do
               "red" -> :red
               "green" -> :green
               "blue" -> :blue
               true -> {:error, :unrecognized_input}
             end

    %{ color => count }
  end

  defp to_integer(string), do: String.to_integer(string)
end
