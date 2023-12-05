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

      map_range.nil? ? input : map_range.call(input)
    end
  end

  class MapRange
    attr_accessor :source, :dest, :length

    def self.from_array(ary)
      new(source: ary[0], dest: ary[1], length: ary[2])
    end

    def initialize(source:, dest:, length:)
      @source = source
      @dest = dest
      @length = length
    end

    def in_range?(input)
      input >= source && input < (source + length)
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
end

if __FILE__ == $PROGRAM_NAME
  ARGV.each do |file|
    Day5.call(file:)
  end
end
