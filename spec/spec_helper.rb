# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  enable_coverage :branch
end
SimpleCov.minimum_coverage line: 90, branch: 60

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'crow'
require 'tmpdir'
require 'fileutils'

RSpec::Matchers.define :all_exist do
  match do |paths|
    @missing_paths = paths.reject { |path| File.exist?(path) }
    @missing_paths.empty?
  end

  failure_message do
    "expected all paths to exist; missing: #{@missing_paths.join(', ')}"
  end
end
