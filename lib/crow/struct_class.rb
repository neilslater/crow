require 'erb'
require 'fileutils'

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

    def copy_project source_dir, target_dir, source_names = { :short_name => 'kaggle_skeleton', :module_name => 'KaggleSkeleton' }
      raise "No source project in #{source_dir}" unless File.directory?( source_dir ) && File.exists?( File.join( source_dir, 'Gemfile' ) )
      FileUtils.mkdir_p target_dir
      Dir.glob( File.join( source_dir, '**', '*' ) ) do |source_file|
        copy_project_file source_file, source_dir, target_dir, source_names
      end
    end

    private

    def copy_project_file source_file, source_dir, target_dir, source_names
      rel_source_file = source_file.sub( File.join(source_dir,'/'), '' )
      return if skip_project_file?( rel_source_file ) || File.directory?( source_file )

      rel_target_file = rel_source_file

      if change_names?( rel_target_file )
        rel_target_file.gsub!( source_names[:short_name], self.short_name )
      end

      target_file = File.join( target_dir, rel_target_file )

      unless File.directory?( File.dirname( target_file ) )
        FileUtils.mkdir_p File.dirname( target_file )
      end

      FileUtils.cp( source_file, target_file )

      if change_names?( rel_target_file )
        change_names_in_file( target_file, source_names )
      end
    end

    def change_names_in_file target_file, source_names
      contents = File.read( target_file )
      contents.gsub!( source_names[:short_name], self.short_name )
      contents.gsub!( source_names[:module_name], self.module_name )
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

    def module_name_from_short_name sname
      parts = sname.split('_')
      parts.map { |part| part[0].upcase + part[1,30] }.join
    end
  end

  class StructClass
    attr_accessor :short_name, :struct_name, :rb_class_name, :attributes, :parent_lib, :init_params

    TEMPLATE_DIR = File.realdirpath( File.join( __dir__, '../../lib/templates' ) )
    TEMPLATES = [ 'struct_dataset.h', 'struct_dataset.c', 'ruby_class_dataset.h', 'ruby_class_dataset.c' ]

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
