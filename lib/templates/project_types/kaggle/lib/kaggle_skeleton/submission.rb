require 'csv'

class KaggleSkeleton::Submission
  CSV_HEADERS = %w[ToyId ElfId StartTime Duration].freeze

  attr_reader :elf_toys, :schedule

  def initialize(schedule)
    raise ArgumentError, 'Schedule must be an NArray' unless schedule.is_a?(NArray)
    raise ArgumentError, 'Schedule must contain integers' unless schedule.typecode == 3
    raise ArgumentError, 'Schedule must be 10M x 3' unless schedule.shape == [3, 10_000_000]

    @schedule = schedule
  end

  def verify
    raise NotImplementedError
  end

  def write_csv(csv_filename)
    raise NotImplementedError

    csv = CSV.open(csv_filename, 'wb')
    csv << CSV_HEADERS

    each_schedule_item do |toy_id, elf_id, _start_min, duration|
      row = [
        toy_id + 1,
        elf_id + 1,
        # (KaggleSkeleton::Clock.mins_to_yymmdd_hhmm( start_min )).join(' '),
        duration
      ]
      csv << row
    end
    csv.close
  end
end
