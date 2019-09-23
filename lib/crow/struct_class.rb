require 'erb'
require 'fileutils'

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
class Crow::StructClass
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
  # @option opts [Array<Hash>] :init_params, if provided these are used to create new Crow::TypeMap objects that describe params to initialise instances of the new class
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
        Crow::TypeMap.create( attr_name, use_opts )
      end
    else
      @attributes = []
    end
    if opts[:init_params]
      @init_params = opts[:init_params].map do | init_param_opts |
        use_opts = init_param_opts.clone
        param_name = use_opts[:name]
        use_opts[:parent_struct] = self
        Crow::TypeMap.create( param_name, use_opts )
      end
    else
      @init_params = []
    end

    @parent_lib = opts[:parent_lib] || Crow::LibDef.new( 'module' )
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
    @attributes << Crow::TypeMap.create( name, opts.merge( parent_struct: self ) )
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
