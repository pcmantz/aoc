#!/usr/local/bin/elixir

defmodule Day1 do
  @moduledoc false

  @zero "zero"
  @one "one"
  @two "two"
  @three "three"
  @four "four"
  @five "five"
  @six "six"
  @seven "seven"
  @eight "eight"
  @nine "nine"

  @digit_string_map %{
    @zero => 0,
    @one => 1,
    @two => 2,
    @three => 3,
    @four => 4,
    @five => 5,
    @six => 6,
    @seven => 7,
    @eight => 8,
    @nine => 9
  }

  @digit_strings Map.keys(@digit_string_map)
  @digit_integers 0..9 |> Enum.to_list() |> Enum.map(&~s(#{&1}))

  def run(filename) do
    sum =
      File.stream!(filename)
      |> Stream.map(&parse_line(&1))
      |> Enum.sum()
  end

  def parse_line(line) do
    tokenize(line)
    |> calibration_value
  end

  def calibration_value(numbers) do
    List.first(numbers) * 10 + List.last(numbers)
  end

  def tokenize(string) when byte_size(string) == 0, do: []

  def tokenize(string) do
    cond do
      token = matches_word(string) ->
        number = @digit_string_map[token]
        [number] ++ tokenize(String.slice(string, (String.length(token) - 1)..-1))

      token = matches_digit(string) ->
        {number, _} = Integer.parse(token)
        [number] ++ tokenize(String.slice(string, 1..-1))

      true ->
        tokenize(String.slice(string, 1..-1))
    end
  end

  def matches_word(line) do
    Enum.find(@digit_strings, fn word -> String.starts_with?(line, word) end)
  end

  def matches_digit(line) do
    Enum.find(@digit_integers, fn num -> String.starts_with?(line, num) end)
  end
end

# Day1Twoex.run("tmp/day1_input.txt")
