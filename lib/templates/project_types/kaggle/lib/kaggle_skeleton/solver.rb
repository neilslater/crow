# frozen_string_literal: true

module KaggleSkeleton
  # Base solver for generated optimization projects.
  class Solver
    def initialize(opts = {})
      assign_options(opts)
    end

    def run
      raise NotImplementedError
    end

    def self.default_opts
      { example: 0 }
    end

    private

    def assign_options(opts)
      @opts = self.class.default_opts.merge(opts)
    end
  end
end
