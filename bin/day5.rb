#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'pry-byebug'

# This defeated me; I don't have a good strategy for reducing the runtime of this The first part was
# fine. though.
#


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

    ORDER = [SEED, SOIL, FERTILIZER, WATER, LIGHT, TEMPERATURE, HUMIDITY, LOCATION].freeze
    ALL = ORDER

    REGEXP = /#{Types::ALL.join('|')}/
  end

  class Almanac
    attr_accessor :type_maps

    def initialize(type_maps:)
      @type_maps = type_maps

      # calculate this
      type_map_map
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

    NUM_RACTORS = 20
    BATCH_SIZE = 100_000

    def lowest_location_in_seed_ranges(ranges)
      dispatcher = Ractor.new { loop { Ractor.yield(Ractor.receive) } }
      workers = (1..NUM_RACTORS).map { |i| build_worker(i, dispatcher) }

      ranges.each do |range|
        batches = range_in_batches(range)
        $stderr.puts("Queuing #{batches.count} batches to process range #{range.inspect}")
        dispatch_batches(dispatcher, batches)
      end

      wait_for_workers(ranges, workers)
    end

    private

    def build_worker(i, dispatcher)
      almanac = Ractor.make_shareable(self)

      Ractor.new(i, dispatcher, almanac) do |i, dispatcher, almanac|
        loop do
          batch = dispatcher.take
          $stderr.puts("worker #{i} processing #{batch.inspect}")

          # NOTE: copypasta from lowest_location_in_seeds because of Proc#isolate
          result = batch.lazy.map { [_1, almanac.seed_location(_1)] }.min { _1[1] <=> _2[1] }
          $stderr.puts("worker #{i} found result #{result.inspect}")

          Ractor.yield(result.dup)
        end
      end
    end

    def range_in_batches(range, batch_size = BATCH_SIZE)
      range.step(batch_size).map do
        range_end = [(_1 + batch_size - 1), range.end].min
        Range.new(_1, range_end)
      end
    end

    def dispatch_batches(dispatcher, batches)
      batches.each do
        batch = Ractor.make_shareable(_1)
        $stderr.puts("dispatching batch #{batch.inspect}")

        dispatcher.send(batch)
      end
    end

    def wait_for_workers(ranges, workers)
      ranges_counts = ranges.map(&:count)

      seed_count = ranges_counts.sum
      total_jobs = ranges_counts.map { Rational(_1, BATCH_SIZE).ceil }.sum

      $stderr.puts("#{total_jobs} jobs to process #{seed_count} seeds")

      jobs_done = 0
      lowest_location = nil

      while jobs_done < total_jobs
        r, result = Ractor.select(*workers)
        jobs_done += 1
        $stderr.puts("receiving result #{result.inspect} (#{jobs_done}/#{total_jobs}) from #{r.inspect}")

        lowest_location ||= result
        lowest_location = [result, lowest_location].min { _1[1] <=> _2[1] }

        $stderr.puts("processed job #{jobs_done}/#{total_jobs}")
      end

      lowest_location
    end
  end

  class TypeMap
    attr_accessor :from, :to, :map_ranges

    def self.merge(left, right)
      left.merge(right)
    end

    def initialize(from:, to:, map_ranges:)
      @from = from
      @to = to
      @map_ranges = map_ranges.sort {_1.source <=> _2.source }
    end

    def call(input)
      map_range = map_ranges.find { |range| range.in_range?(input) }
      return input if map_range.nil?

      map_range.call(input)
    end

    def merge(other)
      raise Error "TypeMaps must be composable to be merged" unless self.to == other.from

      TypeMap.new(
        from: self.from,
        to: other.to,
        map_ranges: other.map_ranges.reduce(self.map_ranges) { MapRange.compose(_2, _1) }
      )
    end
  end

  class MapRange
    attr_accessor :source, :dest, :length

    # TODO: Not functional, don't know if I can ever make it functional.
    #
    #
    def self.compose(map_ranges, new)
      map_ranges.each.with_index do |map_range, index|
        if map_range.in_dest_range?(new.source) && map_range.in_dest_range(new.source_end)
          return
          list_substituting_index(
            map_ranges,
            index,
            [
              MapRange.new(
                source: map_range.source,
                dest: map_range.dest,
                length: new.source - map_range.source
              ),
              MapRange.new(source: new.source, dest: new.dest, length: new.length),
              MapRange.new(
                source: new.source_end + 1,
                dest: new.source_end + 1 + map_range.offset,
                length: map_source.dest_end - new.source_end
              )
            ].filter { _1.length <= 0 }
          )

        elsif map_range.in_dest_range?(new.source)
          replaced_list = list_substituting_index(
            map_ranges,
            index,
            [
              MapRange.new(
                source: map_range.source,
                dest: map_range.dest + new.offset,
                length: new.source - map_range.dest
              ),
              MapRange.new(source: new.source + 1, dest: new.dest, length: new.length)])

          return compose(
                   replaced_list,
                   MapRange.new(
                     source: map_ranges.source_end + 1,
                     dest:  map_ranges.source_end + 1 + map_range.offset,
                     length: new.source_end - map_source.dest_end
                   ))

        elsif map_range.in_dest_range(new.source_end)
          replaced_list = list_substituting_index(
            map_ranges,
            index,
            [
              MapRange.new(
                source: map_range.source,
                dest: map_range.dest + new.offset,
                length: new.source_end - map_range.dest
              ),
              MapRange.new(
                source: map_range.source + 1,
                dest: map_range.dest + 1 + map_range.offset,
                length: map_range.dest_end - new.source_end

              )
            ]
          )

          return compose(
                   replaced_list,
                   MapRange.new(

                   )
                 )

        end

      end
    end

    def self.list_substituting_index(list, index, replacement)
      list[0..i-1] + replacement + list[i+1..-1]
    end

    def self.from_array(ary)
      dest, source, length = ary

      new(source:, dest:, length:)
    end

    def initialize(source:, dest:, length:)
      @source = source
      @dest = dest
      @length = length

      offset
    end

    def source_end
      dest + length - 1
    end

    def dest_end
      dest + length - 1
    end

    def in_range?(input)
      (input >= source) && (input < (source + length))
    end

    def in_dest_range?(input)
      (input >= dest) && (input < (dest + length))
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

    def self.seed_ranges(seeds)
      seeds.each_slice(2).map { _1..(_1 + _2 - 1) }.sort { _1.begin <=> _2.begin }
    end

    def parse_file(file)
      fh = File.open(file)

      line = next_data_line(fh)
      seeds = parse_seed_line(line)

      type_maps = []

      while (section_data = parse_section(fh))
        type_map = TypeMap.new(
          from: section_data[:from],
          to: section_data[:to],
          map_ranges: section_data[:map_ranges].map { MapRange.from_array(_1) }
        )

        type_maps.push(type_map)
      end

      { seeds:, almanac: Almanac.new(type_maps:) }
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

    ractor_lowest_location_in_seeds(almanac, seeds)
  end

  def self.find_lowest_location_from_pairs(filename)
    result = Parser.parse_file(filename)

    almanac = result.fetch(:almanac)
    seed_ranges = Parser.seed_ranges(result.fetch(:seeds))

    almanac.lowest_location_in_seed_ranges(seed_ranges)
  end

  def self.lowest_location_in_seeds(almanac, seeds)
    seeds.map { [_1, almanac.seed_location(_1)] }.min { _1[1] <=> _2[1] }
  end
end

if __FILE__ == $PROGRAM_NAME
  ARGV.each do |file|
    Day5.call(file:)
  end
end
