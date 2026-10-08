# frozen_string_literal: true

require 'erb'
require 'fileutils'

module Crow
  # This class models the available template files, and rendering them based on structure input.
  #
  class StructTemplates
    # The binding used to render templates.
    # @return [Binding]
    attr_reader :struct_binding

    # Base name substituted into generated file names.
    # @return [String]
    attr_reader :short_name

    # Directory containing generated base implementation templates.
    # @return [String]
    TEMPLATE_DIR = File.realdirpath(File.join(__dir__, '../../lib/templates/class_structs'))

    # Base implementation templates rendered for every struct.
    # @return [Array<String>]
    TEMPLATES = ['struct_dataset.h', 'struct_dataset.c', 'ruby_class_dataset.h', 'ruby_class_dataset.c'].freeze

    # Directory containing user-editable Ruby binding templates.
    # @return [String]
    USER_CLASS_TEMPLATE_DIR = File.realdirpath(File.join(__dir__, '../../lib/templates/class_structs'))

    # User-editable Ruby binding templates rendered for every struct.
    # @return [Array<String>]
    USER_CLASS_TEMPLATES = ['class_dataset.h', 'class_dataset.c'].freeze

    # Directory containing user-editable C struct templates.
    # @return [String]
    USER_STRUCT_TEMPLATE_DIR = File.realdirpath(File.join(__dir__, '../../lib/templates/class_structs'))

    # User-editable C struct templates rendered for every struct.
    # @return [Array<String>]
    USER_STRUCT_TEMPLATES = ['dataset.h', 'dataset.c'].freeze

    # Directory containing generated RSpec templates.
    # @return [String]
    SPEC_TEMPLATE_DIR = File.realdirpath(File.join(__dir__, '../../lib/templates/spec'))

    # RSpec templates rendered for every struct.
    # @return [Array<String>]
    SPEC_TEMPLATES = ['dataset_spec.rb.erb'].freeze

    # Creates a renderer for one struct definition.
    # @param [String] short_name base name substituted into generated file names
    # @param [Binding] struct_binding context used to evaluate ERB templates
    def initialize(short_name, struct_binding)
      @struct_binding = struct_binding
      @short_name = short_name
    end

    # Writes four C source files that implement a basic Ruby native extension for the class. The files
    # are split into a Ruby class binding and a struct definition, each of which has a .c and .h file.
    # @param [String] path directory to write files to.
    # @return [void]
    def write(path)
      write_group(path, :base)
    end

    # Writes absent user extension scaffolds after rendering the whole request.
    # @param path [String] extension directory
    def write_user(path)
      write_group(path, :user)
    end

    # Writes generated specs after rendering the whole request.
    # @param path [String] spec directory
    def write_specs(path)
      write_group(path, :spec)
    end

    # Adds one file group to a larger rendered request.
    # @param plan [OutputPlan] destination plan
    # @param path [String] output directory
    # @param group [Symbol] base, user or spec files
    def plan_group(plan, path, group)
      groups.fetch(group).each do |subdir, templates|
        templates.each do |template|
          directory = group == :spec ? SPEC_TEMPLATE_DIR : TEMPLATE_DIR
          source = File.join(directory, template)
          target = template.sub('dataset', short_name).delete_suffix('.erb')
          plan.add(File.join(path, subdir, target), OutputPlan.render(source, struct_binding), preserve: group == :user)
        end
      end
    end

    private

    def groups
      { base: { 'base' => TEMPLATES },
        user: { 'ruby' => USER_CLASS_TEMPLATES, 'lib' => USER_STRUCT_TEMPLATES },
        spec: { '' => SPEC_TEMPLATES } }
    end

    def write_group(path, group)
      plan = OutputPlan.new
      plan_group(plan, path, group)
      plan.write
    end
  end

  # This class models the description of dual Ruby class and C struct code.
  #
  # An object of the class describes a C struct, and its Ruby representation.
  #
  # @example Define a basic C struct with two attributes and write its files to a folder
  #  structdef = Crow::StructClass.new('the_class',
  #    attributes: [{ name: 'number', ctype: :int },
  #                 { name: 'values', ctype: :double, pointer: true }])
  #  structdef.write('/path/to/target_project/ext/the_module')
  #
  class StructClass
    include StructAttributes
    include StructContract
    include SpecValues

    # The label used for file names and struct pointers relating to this struct
    # @return [String]
    attr_accessor :short_name

    # The label used for struct type (by default derived from short_name)
    # @return [String]
    attr_accessor :struct_name

    # The name used for Ruby Class wrapper for this type (by default derived from short_name)
    # @return [String]
    attr_accessor :rb_class_name

    # List of attributes defined in the struct and class
    # @return [Array<Crow::TypeMap>]
    attr_accessor :attributes

    # The container library for the struct. Although you can generate struct wrappers without this being set,
    # some templated code needs to know the correct container.
    # @return [Crow::LibDef]
    attr_accessor :parent_lib

    # List of params used to initialize a struct or class of this type
    # @return [Array<Crow::TypeMap>]
    attr_accessor :init_params

    # Creates a new struct description.
    # @param [String] short_name identifying name for struct and class
    # @param [Hash] opts
    # @option opts [String] :struct_name if provided then over-rides name automatically derived from short_name
    # @option opts [String] :rb_class_name if provided then over-rides name automatically derived from short_name
    # @option opts [Array<Hash>] :attributes, if provided these are used to create new Crow::TypeMap objects that
    #                            describe attributes
    # @option opts [Array<Hash>] :init_params, if provided these are used to create new Crow::TypeMap objects
    #                            that describe params to initialise instances of the new class
    # @option opts [Crow::LibDef] :parent_lib, if provided then sets parent_lib
    # @return [Crow::StructClass]
    #
    def initialize(short_name, opts = {})
      raise "Short name '#{short_name}' cannot be used" unless /\A[a-zA-Z0-9_]+\z/.match?(short_name)

      @short_name = short_name
      @struct_name = opts[:struct_name] || struct_name_from_short_name(@short_name)
      @rb_class_name = opts[:rb_class_name] || @struct_name
      @attributes = create_attributes(opts)
      @init_params = create_init_params(opts)

      @parent_lib = opts[:parent_lib] || Crow::LibDef.new('module')
    end

    # Writes four C source files that implement a basic Ruby native extension for the class. The files
    # are split into a Ruby class binding and a struct definition, each of which has a .c and .h file.
    # @param [String] path directory to write files to.
    # @return [void]
    def write(path)
      ModelValidation.structure(self)
      templates.write(path)
    end

    # Writes user C files that go in ext/lib/ruby and ext/lib/lib for developer to extend with the
    # main C-based functionality of the library.
    # @param [String] path directory to write files to.
    # @return [void]
    def write_user(path)
      ModelValidation.structure(self)
      templates.write_user(path)
    end

    # Writes a Ruby source file containing basic spec examples that exercise standard functions of
    # the structure as defined.
    # @param [String] path directory to write spec files to.
    # @return [void]
    def write_specs(path)
      ModelValidation.structure(self)
      templates.write_specs(path)
    end

    # Adds all struct output to a validated project plan.
    # @param plan [OutputPlan] project plan
    # @param target [String] project root
    def plan_project(plan, target)
      ext = File.join(target, 'ext', lib_short_name)
      templates.plan_group(plan, ext, :base)
      templates.plan_group(plan, ext, :user)
      templates.plan_group(plan, File.join(target, 'spec'), :spec)
    end

    # Adds an attribute definition to the struct/class description.
    # @param [Hash] opts options passed to {TypeMapFactory.create_typemap}
    # @return [Crow::TypeMap] the new attribute definition
    def add_attribute(opts = {})
      @attributes << Crow::TypeMapFactory.create_typemap(opts.merge(parent_struct: self))
    end

    # Short file-name identifier of the containing library.
    # @return [String]
    def lib_short_name
      parent_lib.short_name
    end

    # Ruby module name of the containing library.
    # @return [String]
    def lib_module_name
      parent_lib.module_name
    end

    # C identifier for the generated Ruby class.
    # @return [String]
    def full_class_name
      "#{parent_lib.module_name}_#{rb_class_name}"
    end

    # Fully qualified Ruby constant name for the generated class.
    # @return [String]
    def full_class_name_ruby
      "#{parent_lib.module_name}::#{rb_class_name.gsub('_', '::')}"
    end

    private

    def templates
      StructTemplates.new(short_name, binding)
    end

    def create_attributes(opts)
      if opts[:attributes]
        opts[:attributes].map do |attr_opts|
          use_opts = attr_opts.clone
          use_opts[:parent_struct] = self
          Crow::TypeMapFactory.create_typemap(use_opts)
        end
      else
        []
      end
    end

    def create_init_params(opts)
      if opts[:init_params]
        opts[:init_params].map do |init_param_opts|
          use_opts = init_param_opts.clone
          use_opts[:parent_struct] = self
          Crow::TypeMapFactory.create_typemap(use_opts)
        end
      else
        []
      end
    end

    def struct_name_from_short_name(sname)
      sname.split('_').map { |part| part[0].upcase + part[1, 30] }.join
    end
  end
end
