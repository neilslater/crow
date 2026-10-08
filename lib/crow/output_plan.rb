# frozen_string_literal: true

module Crow
  # Renders a complete write request before touching any output file.
  class OutputPlan
    # Creates an empty plan.
    def initialize
      @files = {}
    end

    # Adds a rendered file, retaining the existing user-file skip policy.
    # @param path [String] output path
    # @param contents [String] rendered bytes
    # @param preserve [Boolean] whether existing files belong to the user
    def add(path, contents, preserve: false)
      path = File.expand_path(path)
      raise ArgumentError, "Duplicate output path: #{path}" if @files.key?(path)

      @files[path] = [contents, preserve]
    end

    # Applies an already rendered plan; filesystem failures are not transactional.
    def write
      @files.each do |path, (contents, preserve)|
        next if preserve && File.exist?(path)

        FileUtils.mkdir_p(File.dirname(path))
        File.binwrite(path, contents)
      end
    end

    # Renders a template with a path-bearing diagnostic and preserved cause.
    # @param path [String] template path
    # @param context [Binding] template context
    # @param contents [String] optional renamed template contents
    # @return [String] rendered bytes
    def self.render(path, context, contents = File.read(path))
      ERB.new(contents, trim_mode: '-').result(context)
    rescue StandardError => e
      raise ArgumentError, "Cannot render #{path}: #{e.message}"
    end
  end
end
