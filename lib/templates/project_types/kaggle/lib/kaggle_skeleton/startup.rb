# frozen_string_literal: true

require 'csv'

# Generated project namespace and data-loading entry points.
module KaggleSkeleton
  DATA_PATH = File.realpath(File.join(File.dirname(__FILE__), '../..', 'data'))
  CSV_PATH = File.join(DATA_PATH, 'data_rev2.csv')
  IMPORTED_PATH = File.join(DATA_PATH, 'data_narray.dat')
  IMPORTED_SHAPE = [2, 10_000_000].freeze

  DATA = if File.exist?(IMPORTED_PATH)
           Numo::Int32.from_binary(File.binread(IMPORTED_PATH), IMPORTED_SHAPE)
         else
           warn 'Cannot load data, need to run first-time import.'
           nil
         end

  def self.data
    DATA
  end

  def self.ready_to_import?
    File.exist?(CSV_PATH)
  end

  def self.import_from_csv
    raise NotImplementedError, 'Implement CSV import for the generated project schema'
  end

  def self.ready_to_run?
    !!DATA
  end
end
