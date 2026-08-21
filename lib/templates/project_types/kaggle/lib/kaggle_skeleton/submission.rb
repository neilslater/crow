# frozen_string_literal: true

require 'csv'

# Generated-project submission writer interface.
module KaggleSkeleton
  # Validates and writes competition submissions.
  class Submission
    CSV_HEADERS = %w[ToyId ElfId StartTime Duration].freeze

    attr_reader :elf_toys, :schedule

    def initialize(schedule)
      raise ArgumentError, 'Schedule must be a Numo::NArray' unless schedule.is_a?(Numo::NArray)
      raise ArgumentError, 'Schedule must contain 32-bit integers' unless schedule.is_a?(Numo::Int32)
      raise ArgumentError, 'Schedule must be 10M x 3' unless schedule.shape == [3, 10_000_000]

      @schedule = schedule
    end

    def verify
      raise NotImplementedError
    end

    def write_csv(_csv_filename)
      raise NotImplementedError
    end
  end
end
