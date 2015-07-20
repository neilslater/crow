require 'erb'

module Crow
  class StructClass
    attr_accessor :short_name, :struct_name, :attributes

    TEMPLATE_DIR = File.realdirpath( File.join( __dir__, '../../lib/templates' ) )
    TEMPLATES = [ 'struct_dataset.h', 'struct_dataset.c', 'ruby_class_dataset.h', 'ruby_class_dataset.c' ]

    def initialize( short_name, opts = {} )
      raise "Short name '#{short_name}' cannot be used" if short_name !~ /\A[a-zA-Z0-9_]+\z/
      @short_name = short_name
      @struct_name = opts[:struct_name] || struct_name_from_short_name( @short_name )
      if opts[:attributes]
        @attributes = opts[:attributes].map do | attr_opts |
          attr_name = attr_opts[:name]
          Attribute.create( attr_name, attr_opts )
        end
      else
        @attributes = []
      end
    end

    def write path
      TEMPLATES.each do |template|
        File.open( File.join( path, template.sub( /dataset/, short_name ) ), 'w' ) do |file|
          file.puts render( File.join( TEMPLATE_DIR, template ) )
        end
      end
    end

    def add_attribute name, opts = {}
      @attributes << Attribute.create( name, opts )
    end

    def any_narray?
      @attributes.any? { |a| [:NARRAY].include?( a.ctype ) }
    end

    def any_alloc?
      @attributes.any? { |a| a.needs_alloc? }
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
