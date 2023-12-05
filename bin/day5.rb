#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'pry-byebug'

class Day5
  class Types
    SEED = 'seed'
    SOIL = 'soil'
    FERTILIZER = 'fertilizer'
    WATER = 'water'
    LIGHT = 'light'
    TEMPERATURE = 'temperature'
    HUMIDITY = 'humidity'
    LOCATION = 'location'

    ORDER = [SEED, SOIL, FERTILIZER, WATER, LIGHT, TEMPERATURE, HUMIDITY, LOCATION]
    ALL = ORDER

    REGEXP = /#{Types::ALL.join('|')}/
  end

  class Almanac
    attr_accessor :type_maps

    def initialize(type_maps:)
      @type_maps = type_maps
    end

    def seed_location(seed)
      Types::ORDER.each_cons(2).reduce(seed) do |pos, cons|
        range_map = get_map(*cons)

        range_map.call(pos)
      end
    end

    def get_map(from, to)
      type_map_map.dig(from, to)
    end

    def type_map_map
      return @type_map_map if defined?(@type_map_map)

      @type_map_map = type_maps.each_with_object({}) do |type_map, memo|
        from = type_map.from
        to = type_map.to

        memo[from] ||= {}
        memo[from][to] = type_map
      end
    end
  end

  class TypeMap
    attr_accessor :from, :to, :map_ranges

    def initialize(from:, to:, map_ranges:)
      @from = from
      @to = to
      @map_ranges = map_ranges
    end

    def call(input)
      map_range = map_ranges.find { |range| range.in_range?(input) }
      return input if map_range.nil?

      map_range.call(input)
    end
  end

  class MapRange
    attr_accessor :source, :dest, :length

    def self.from_array(ary)
      dest, source, length = ary

      new(source:, dest:, length:)
    end

    def initialize(source:, dest:, length:)
      @source = source
      @dest = dest
      @length = length
    end

    def in_range?(input)
      (input >= source) && (input < (source + length))
    end

    def call(input)
      in_range?(input) ? input + offset : input
    end

    def offset
      return @offset if defined?(@offset)

      @offset = dest - source
    end
  end

  class Parser
    MAP_HEADER_LINE_REGEXP = /^(?<from>#{Types::REGEXP})-to-(?<to>#{Types::REGEXP})\s+map:\s*$/

    def self.parse_file(...)
      new.parse_file(...)
    end

    def parse_file(file)
      fh = File.open(file)

      line = next_data_line(fh)
      seeds = parse_seed_line(line)

      type_maps = []

      while section_data = parse_section(fh)
        type_map = TypeMap.new(
          from: section_data[:from],
          to: section_data[:to],
          map_ranges: section_data[:map_ranges].map { MapRange.from_array(_1) }
        )

        type_maps.push(type_map)
      end

      {seeds: seeds, almanac: Almanac.new(type_maps: type_maps)}
    end

    def parse_seed_line(line)
      match = /seeds:\s+(.*)$/.match(line)
      seeds_string = match.captures.first

      num_string_to_ints(seeds_string)
    end

    def parse_section(fh)
      header_line = next_data_line(fh)
      return if header_line.nil?

      match = MAP_HEADER_LINE_REGEXP.match(header_line)

      captures = match.named_captures
      from = captures['from']
      to = captures['to']

      ranges = []
      while (data_line = fh.gets)
        break if data_line.match?(/^\s*$/)

        ranges.push(num_string_to_ints(data_line))
      end

      { from:, to:, map_ranges: ranges }
    end

    def parse_map_line(line); end

    def num_string_to_ints(string)
      string.strip.split(/\s+/).map { _1.strip.to_i }
    end

    def next_data_line(fh)
      while (line = fh.gets)
        return line unless line.match?(/^\s*$/)
      end

      nil
    end
  end

  def self.find_lowest_location(filename)
    result = Parser.parse_file(filename)

    seeds = result.fetch(:seeds)
    almanac = result.fetch(:almanac)

    lowest_location_in_seeds(almanac, seeds)
  end

  def self.find_lowest_location_from_pairs(filename)
    result = Parser.parse_file(filename)

    almanac = result.fetch(:almanac)
    seed_ranges =
      result
        .fetch(:seeds)
        .each_slice(2)
        .map { _1..(_1 + _2 - 1) }
        .sort { _1.begin <=> _2.begin }

    lowest_locations = seed_ranges.map { lowest_location_in_seeds(almanac, _1) }

    lowest_locations.min
  end

  def self.lowest_location_in_seeds(almanac, seeds)
    seeds.map { [_1, almanac.seed_location(_1) ] }.max { _1[1] <=> _2[1] }
  end

  NUM_RACTORS = 20

  def self.ractor_lowest_location_in_seeds(almanac, seeds)
    pipe = Ractor.new { loop { Ractor.yield(Ractor.receive) } }
    shareable_almanac = Ractor.make_shareable(almanac)
    seed_count = seeds.count

    workers = (1..NUM_RACTORS).map do |i|
      Ractor.new(i, pipe, shareable_almanac) do |i, pipe, almanac|
        while seed = pipe.take do
          Ractor.yield([seed, almanac.seed_location(seed)])
        end
      end
    end

    # Start calculating
    seeds.each { |seed| pipe.send(seed) }

    lowest_location = nil
    while calculated_seeds < seed_count
      ractor, (seed, location) = Ractor.select(*workers)

      lowest_location ||= [seed, location]
      lowest_location = lowest_location[1] =< location ? lowest_location : [seed, location]

      calculated_seeds += 1
    end

    lowest_location
  end

end

if __FILE__ == $PROGRAM_NAME
  ARGV.each do |file|
    Day5.call(file:)
  end
end
