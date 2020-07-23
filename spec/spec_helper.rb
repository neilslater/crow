# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  enable_coverage :branch
end
SimpleCov.minimum_coverage line: 99, branch: 99

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'crow'
require 'tmpdir'
require 'fileutils'
