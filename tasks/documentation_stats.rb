# frozen_string_literal: true

require 'yard'

# Enforces completeness using the same object selection as YARD's statistics.
class DocumentationStats < YARD::CLI::Stats
  def initialize
    super
    @missing_documentation = 0
  end

  def run(*args)
    super
    abort 'Public API documentation is incomplete' unless @missing_documentation.zero?
  end

  def output(name, data, undocumented = nil)
    @missing_documentation += undocumented if undocumented
    super
  end
end
