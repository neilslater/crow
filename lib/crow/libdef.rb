# frozen_string_literal: true

require 'erb'
require 'fileutils'

module Crow
  # Implements rules for how template files should be processed
  #
  module LibTemplateRules
    private

    def skip_project_file?(rel_source_file)
      return true if rel_source_file.start_with?('tmp')
      return true if rel_source_file.end_with?('.DS_Store')

      false
    end

    def change_names?(rel_source_file)
      rel_ext = File.extname(rel_source_file)
      return true if rel_ext =~ /\A\.(?:c|h|txt|rb|gemspec|md)\z/ || rel_ext == ''

      false
    end

    def contains_user_code?(rel_source_file)
      # There may be a few mixed user/generated files in future, but for now everything is one or other
      return true if %r{\A(?:ruby|lib)/}.match?(rel_source_file)

      false
    end

    def run_template?(rel_source_file)
      rel_ext = File.extname(rel_source_file)
      return true if /\A\.(?:c|h|rb)\z/.match?(rel_ext)

      false
    end
  end

  # This class models the general description of a Ruby library with C extensions. It is the "root"
  # class for generating new project code.
  #
  # An object of the class describes a specific library, and contains descriptions of Ruby-wrapped C
  # structs. It can be used to create starter project files from a template, and add hybrid Ruby/C
  # structs to it.
  #
  # NB Some functions are incomplete and manual editing may be required in order to create a working
  # Ruby project.
  #
  # @example Create a new Kaggle project based on template files
  #  libdef = Crow::LibDef.new('the_module', structs: [{ name: 'hello',
  #    attributes: [{ name: 'hi', ctype: :NARRAY_DOUBLE }] }])
  #  libdef.create_project('/path/to/target_project')
  #
  class LibDef
    include LibTemplateRules

    # Directory containing the supported project skeletons.
    # @return [String]
    TEMPLATE_DIR = File.realdirpath(File.join(__dir__, '../../lib/templates/project_types'))

    # Identifiers accepted by {#create_project}.
    # @return [Array<String>]
    TEMPLATES = ['kaggle'].freeze

    # The label used for file names relating to the whole project.
    # E.g. the lib folder will contain /lib/<short_name>/<short_name>.rb
    # @return [String]
    attr_accessor :short_name

    # The main module namespace for the project
    # @return [String]
    attr_accessor :module_name

    # Definitions of all the C structs that the project wraps
    # @return [Array<Crow::StructClass>]
    attr_accessor :structs

    # Creates a new project description.
    # @param [String] short_name identifying name for project library files
    # @param [Hash] opts
    # @option opts [String] :module_name, if provided then over-rides name automatically derived from short_name
    # @option opts [Array<Hash>] :structs, if provided these are used to create new Crow::StructClass objects
    # @return [Crow::LibDef]
    #
    def initialize(short_name, opts = {})
      raise "Short name '#{short_name}' cannot be used" unless /\A[a-zA-Z0-9_]+\z/.match?(short_name)

      @short_name = short_name
      @module_name = opts[:module_name] || module_name_from_short_name(@short_name)
      @structs = create_structs(opts)
    end

    # Writes project files from a standard Crow template.
    # @param [String] target_dir folder where files will be copied to. New files will be written,
    #                 existing files are skipped.
    # @param [String] project_type identifier for template. Supported value is `kaggle`.
    # @return [void]
    #
    def create_project(target_dir, project_type = 'kaggle')
      source_dir = check_pre_create_project(project_type)
      ModelValidation.library(self)
      plan = OutputPlan.new
      plan_project(plan, source_dir, target_dir)
      structs.each { |struct| struct.plan_project(plan, target_dir) }
      plan.write
    end

    private

    def create_structs(opts)
      if opts[:structs]
        opts[:structs].map do |struct_opts|
          use_opts = struct_opts.clone
          struct_name = use_opts[:name]
          use_opts[:parent_lib] = self
          Crow::StructClass.new(struct_name, use_opts)
        end
      else
        []
      end
    end

    def check_pre_create_project(project_type)
      raise "Unknown project type '#{project_type}" unless TEMPLATES.include?(project_type)

      source_dir = File.join(TEMPLATE_DIR, project_type)
      unless File.directory?(source_dir) && File.exist?(File.join(source_dir, 'Gemfile'))
        raise "No source project in #{source_dir}"
      end

      source_dir
    end

    def plan_project(plan, source_dir, target_dir)
      Dir.glob(File.join(source_dir, '**', '*')).each do |source|
        relative = source.delete_prefix("#{source_dir}/")
        next if File.directory?(source) || skip_project_file?(relative)

        plan_project_file(plan, source, relative, target_dir)
      end
    end

    def plan_project_file(plan, source, relative, target_dir)
      contents = File.binread(source)
      if change_names?(relative)
        relative = relative.gsub('kaggle_skeleton', short_name)
        contents = contents.gsub('kaggle_skeleton', short_name).gsub('KaggleSkeleton', module_name)
      end
      contents = OutputPlan.render(source, binding, contents) if run_template?(relative)
      plan.add(File.join(target_dir, relative), contents, preserve: contains_user_code?(relative))
    end

    def module_name_from_short_name(sname)
      parts = sname.split('_')
      parts.map { |part| part[0].upcase + part[1, 30] }.join
    end
  end
end
