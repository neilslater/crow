require 'erb'

# m = Crow::LibDef.new( 'the_module', { :structs => [ { :name => 'hello', :attributes => [{:name=>'hi',:ctype=>:NARRAY}] } ] } )
# m.structs.first.write( '/tmp' )

module Crow
  class LibDef
    attr_accessor :short_name, :module_name, :structs

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

    private

    def module_name_from_short_name sname
      parts = sname.split('_')
      parts.map { |part| part[0].upcase + part[1,30] }.join
    end
  end

  class StructClass
    attr_accessor :short_name, :struct_name, :attributes, :parent_lib, :init_params

    TEMPLATE_DIR = File.realdirpath( File.join( __dir__, '../../lib/templates' ) )
    TEMPLATES = [ 'struct_dataset.h', 'struct_dataset.c', 'ruby_class_dataset.h', 'ruby_class_dataset.c' ]

    def initialize( short_name, opts = {} )
      raise "Short name '#{short_name}' cannot be used" if short_name !~ /\A[a-zA-Z0-9_]+\z/
      @short_name = short_name
      @struct_name = opts[:struct_name] || struct_name_from_short_name( @short_name )
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

    def write path
      TEMPLATES.each do |template|
        File.open( File.join( path, template.sub( /dataset/, short_name ) ), 'w' ) do |file|
          file.puts render( File.join( TEMPLATE_DIR, template ) )
        end
      end
    end

    def add_attribute name, opts = {}
      @attributes << TypeMap.create( name, opts )
    end

    def any_narray?
      @attributes.any? { |a| a.is_narray? }
    end

    def narray_attributes
      @attributes.select { |a| a.is_narray? }
    end

    def any_alloc?
      @attributes.any? { |a| a.needs_alloc? }
    end

    def needs_init?
      any_narray? || any_alloc?
    end

    def init_attributes
      @attributes.select { |a| a.needs_alloc? }
    end

    def simple_attributes
      @attributes.reject { |a| a.needs_alloc? || a.is_narray? }
    end

    def lib_short_name
      parent_lib.short_name
    end

    def lib_module_name
      parent_lib.module_name
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
