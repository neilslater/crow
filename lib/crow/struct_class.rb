require 'erb'
require 'fileutils'

module Crow
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
  # @example Create a new Kaggle project based on template file
  #  libdef = Crow::LibDef.new('the_module', :structs => [ { :name => 'hello', :attributes => [{:name=>'hi',:ctype=>:NARRAY_DOUBLE}] } ] )
  #  libdef.create_project( '/path/to/target_project' )
  #
  class LibDef
    TEMPLATE_DIR = File.realdirpath( File.join( __dir__, '../../lib/templates/project_types' ) )
    TEMPLATES = [ 'kaggle' ]

    # The label used for file names relating to the whole project. E.g. the lib folder will contain /lib/<short_name>/<short_name>.rb
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
    def initialize( short_name, opts = {} )
      raise "Short name '#{short_name}' cannot be used" if short_name !~ /\A[a-zA-Z0-9_]+\z/
      @short_name = short_name
      @module_name = opts[:module_name] || module_name_from_short_name( @short_name )
      if opts[:structs]
        @structs = opts[:structs].map do | struct_opts |
          use_opts = struct_opts.clone
          struct_name = use_opts[:name]
          use_opts[:parent_lib] = self
          StructClass.new( struct_name, use_opts )
        end
      else
        @structs = []
      end
    end

    # Writes project files copied from a template directory.
    # @param [String] source_dir template folder that files are recursively copied from.
    # @param [String] target_dir folder where files will be copied to. New files will be written, existing files are skipped.
    # @option source_names [String] :source_short_name, name used in template project file names and content, will be globally replaced
    # @option source_names [String] :source_module_name, namespace used in template project content, will be globally replaced
    # @return [true]
    #
    def copy_project source_dir, target_dir, source_names = { :source_short_name => 'kaggle_skeleton', :source_module_name => 'KaggleSkeleton' }
      raise "No source project in #{source_dir}" unless File.directory?( source_dir ) && File.exists?( File.join( source_dir, 'Gemfile' ) )
      FileUtils.mkdir_p target_dir
      Dir.glob( File.join( source_dir, '**', '*' ) ) do |source_file|
        copy_project_file source_file, source_dir, target_dir, source_names
      end
      true
    end

    # Writes project files from a standard Crow template.
    # @param [String] project_type identifier for template. Supported value 'kaggle'.
    # @param [String] target_dir folder where files will be copied to. New files will be written, existing files are skipped.
    # @return [true]
    #
    def create_project target_dir, project_type = 'kaggle'
      raise "Unknown project type '#{project_type}" unless TEMPLATES.include?( project_type )
      source_dir = File.join( TEMPLATE_DIR, project_type )
      raise "No source project in #{source_dir}" unless File.directory?( source_dir ) && File.exists?( File.join( source_dir, 'Gemfile' ) )

      source_names = { :source_short_name => 'kaggle_skeleton', :source_module_name => 'KaggleSkeleton' }
      FileUtils.mkdir_p target_dir
      Dir.glob( File.join( source_dir, '**', '*' ) ) do |source_file|
        copy_project_file source_file, source_dir, target_dir, source_names
      end
      true
    end

    private

    def copy_project_file source_file, source_dir, target_dir, source_names
      rel_source_file = source_file.sub( File.join(source_dir,'/'), '' )
      return if skip_project_file?( rel_source_file ) || File.directory?( source_file )

      rel_target_file = rel_source_file

      if change_names?( rel_target_file )
        rel_target_file.gsub!( source_names[:source_short_name], self.short_name )
      end

      target_file = File.join( target_dir, rel_target_file )

      return if File.exists?( target_file )

      unless File.directory?( File.dirname( target_file ) )
        FileUtils.mkdir_p File.dirname( target_file )
      end

      FileUtils.cp( source_file, target_file )

      if change_names?( rel_target_file )
        change_names_in_file( target_file, source_names )
      end

      if run_template?( rel_target_file )
        # TODO: Apply template to file
      end
    end

    def change_names_in_file target_file, source_names
      contents = File.read( target_file )
      contents.gsub!( source_names[:source_short_name], self.short_name )
      contents.gsub!( source_names[:source_module_name], self.module_name )
      File.open( target_file, 'w' ) { |file| file.puts contents }
    end

    def skip_project_file? rel_source_file
      return true if rel_source_file =~ /\Atmp/
      false
    end

    def change_names? rel_source_file
      rel_ext = File.extname( rel_source_file )
      return true if rel_ext =~ /\A\.(?:c|h|txt|rb|gemspec|md)\z/ || rel_ext == ''
      false
    end

    def run_template? rel_source_file
      rel_ext = File.extname( rel_source_file )
      return true if rel_ext =~ /\A\.(?:c|h|rb)\z/
      false
    end

    def module_name_from_short_name sname
      parts = sname.split('_')
      parts.map { |part| part[0].upcase + part[1,30] }.join
    end
  end

  # This class models the description of dual Ruby class and C struct code.
  #
  # An object of the class describes a C struct, and its Ruby representation.
  #
  # NB There are limits to flexibility in the descriptions.
  #
  # @example Define a basic C struct with two attributes and write its files to a folder
  #  structdef = Crow::StructClass.new( 'the_class',
  #    :attributes => [{:name=>'number',:ctype=>:int}, {:name=>'values',:ctype=>:double,:pointer=>true}] } ] )
  #  structdef.write( '/path/to/target_project/ext/the_module' )
  #
  class StructClass
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

    TEMPLATE_DIR = File.realdirpath( File.join( __dir__, '../../lib/templates/class_structs' ) )
    TEMPLATES = [ 'struct_dataset.h', 'struct_dataset.c', 'ruby_class_dataset.h', 'ruby_class_dataset.c' ]

    # Creates a new struct description.
    # @param [String] short_name identifying name for struct and class
    # @param [Hash] opts
    # @option opts [String] :struct_name if provided then over-rides name automatically derived from short_name
    # @option opts [String] :rb_class_name if provided then over-rides name automatically derived from short_name
    # @option opts [Array<Hash>] :attributes, if provided these are used to create new Crow::TypeMap objects that describe attributes
    # @option opts [Array<Hash>] :init_params, if provided these are used to create new Crow::TypeMap objects that describe params to initialise of the new class
    # @option opts [Crow::LibDef] :parent_lib, if provided then sets parent_lib
    # @return [Crow::StructClass]
    #
    def initialize( short_name, opts = {} )
      raise "Short name '#{short_name}' cannot be used" if short_name !~ /\A[a-zA-Z0-9_]+\z/
      @short_name = short_name
      @struct_name = opts[:struct_name] || struct_name_from_short_name( @short_name )
      @rb_class_name = opts[:rb_class_name] || @struct_name
      if opts[:attributes]
        @attributes = opts[:attributes].map do | attr_opts |
          use_opts = attr_opts.clone
          attr_name = use_opts[:name]
          use_opts[:parent_struct] = self
          TypeMap.create( attr_name, use_opts )
        end
      else
        @attributes = []
      end
      if opts[:init_params]
        @init_params = opts[:init_params].map do | init_param_opts |
          param_name = init_param_opts[:name]
          TypeMap.create( param_name, init_param_opts )
        end
      else
        @attributes = []
      end

      @parent_lib = opts[:parent_lib] || LibDef.new( 'module' )
    end

    # Writes four C source files that implement a basic Ruby native extension for the class. The files
    # are split into a Ruby class binding and a struct definition, each of which has a .c and .h file.
    # @param [String] path directory to write files to.
    # @return [true]
    def write path
      TEMPLATES.each do |template|
        File.open( File.join( path, template.sub( /dataset/, short_name ) ), 'w' ) do |file|
          file.puts render( File.join( TEMPLATE_DIR, template ) )
        end
      end
      true
    end

    # Adds an attribute definition to the struct/class description.
    # @param [String] name identifier used for the attribute in C and Ruby references
    # @param [Hash] opts passed to Crow::TypeMap constructor
    # @return [Crow::TypeMap] the new attribute definition
    def add_attribute name, opts = {}
      @attributes << TypeMap.create( name, opts )
    end

    # Whether any of the attributes are NArray objects.
    # @return [Boolean]
    def any_narray?
      @attributes.any? { |a| a.is_narray? }
    end

    # List of attributes which contain NArray objects.
    # @return [Array<Crow::TypeMap>]
    def narray_attributes
      @attributes.select { |a| a.is_narray? }
    end

    def any_alloc?
      @attributes.any? { |a| a.needs_alloc? }
    end

    def needs_init?
      any_narray? || any_alloc?
    end

    def alloc_attributes
      @attributes.select { |a| a.needs_alloc? }
    end

    def simple_attributes
      @attributes.reject { |a| a.needs_alloc? || a.is_narray? }
    end

    def simple_attributes_with_init
      @attributes.reject { |a| a.needs_alloc? || a.is_narray? }.select(&:needs_init?)
    end

    def lib_short_name
      parent_lib.short_name
    end

    def lib_module_name
      parent_lib.module_name
    end

    def full_class_name
      parent_lib.module_name + '_' + rb_class_name
    end

    def full_class_name_ruby
      parent_lib.module_name + '::' + rb_class_name.gsub(/_/,'::')
    end

    private

    def render template_file
      erb = ERB.new( File.read( template_file ), 0, '-' )
      erb.result( binding )
    end

    def struct_name_from_short_name sname
      parts = sname.split('_')
      parts.map { |part| part[0].upcase + part[1,30] }.join
    end
  end
end
