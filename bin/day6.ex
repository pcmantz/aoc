#!/usr/local/bin/elixir

defmodule Day6 do
  @moduledoc """
  Solutions for Dauy 6 of Advent of Code (https://adventofcode.com/).
  """

  defmodule Race do
    defstruct [:time, :record]

    def record_beating_score(races) do
      races
      |> Enum.map(&( winning_times(&1) ))
      |> Enum.map(&( Enum.count(&1) ))
      |> Enum.product
    end

    def winning_times(race) do
      %{time: time, record: record} = race

      winning_holds = (0..time)
      |> Enum.map(&( Race.distance_for_hold_and_time(&1, time) ))
      |> Enum.filter(&( &1 > record ))
    end


    def long_race_winning_times do
      time = 60808676
      record = 601116315591300

      (14..(time-14))
      |> Stream.map(&( Race.distance_for_hold_and_time(&1, time) ))
      |> Stream.filter(&( &1 > record ))
      |> Enum.count
    end


    def distance_for_hold_and_time(hold, time) do
      run_time = time - hold

      run_time * hold
    end
  end


  defmodule Parser do
    @moduledoc """
    Parser for Day 6. This should read a file and turn it into the relevant structs. defined above.
    """

    def read_file(filename) do
      lines = File.read(filename)|> elem(1) |> String.split("\n")
      [time_line, distance_line, _] = lines

      [ _, times_string] = Regex.run(~r/^Time:\s+(.*)$/, time_line)
      [ _, distances_string] = Regex.run(~r/^Distance:\s+(.*)$/, distance_line)

      times = parse_number_string(times_string)
      distances = parse_number_string(distances_string)
      race_pairs = Enum.zip([times, distances])

      Enum.map(race_pairs, &( struct(Race, %{ time: elem(&1, 0), record: elem(&1, 1) })))
    end

    def parse_number_string(number_string) do
      strings = number_string
      |> String.trim
      |> String.split(~r/\s+/)

      Enum.map(strings, &( string_to_integer(&1) ))
    end

    def string_to_integer(str) do
      str |> String.trim |> Integer.parse |> elem(0)
    end
  end
end
