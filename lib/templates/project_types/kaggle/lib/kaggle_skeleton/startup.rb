require 'csv'

module KaggleSkeleton
  DATA_PATH = File.realpath(File.join(File.dirname(__FILE__), '../..', 'data'))
  CSV_PATH = File.join(DATA_PATH, 'data_rev2.csv')
  IMPORTED_PATH = File.join(DATA_PATH, 'data_narray.dat')

  if File.exist?(IMPORTED_PATH)
    imported_data = File.open(TOYS_PATH, 'rb') { |file| Marshal.load(file) }
  else
    imported_data = nil
    puts 'Cannot load data, need to run first-time import.'
  end

  DATA = imported_data

  def self.data
    DATA
  end

  def self.ready_to_import?
    File.exist?(CSV_PATH)
  end

  def self.import_from_csv
    raise NotImplementedError

    data = NArray.int(2, 10_000_000)

    puts "Reading #{CSV_PATH}"

    csv = CSV.open(CSV_PATH)
    header = csv.readline
    raise "Did not recognise header #{header.inspect}" unless header == %w[ToyId Arrival_time Duration]

    csv.each do |line|
      id  = line[0].to_i
      dt  = line[1].split(/\s+/).map(&:to_i)
      dur = line[2].to_i
      # abs_mins = KaggleSkeleton::Clock.from_yymmdd_hhmm( *dt )
      data[0, id - 1] = abs_mins
      data[1, id - 1] = dur
      p [line, [abs_mins, dur]] if id % 100_000 == 0
    end
  end

  def self.ready_to_run?
    !!DATA
  end
end
