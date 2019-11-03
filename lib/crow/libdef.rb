require 'erb'
require 'fileutils'

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
class Crow::LibDef
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
        Crow::StructClass.new( struct_name, use_opts )
      end
    else
      @structs = []
    end
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
    copy_project( source_dir, target_dir, source_names )

    spec_dir = File.join( target_dir, 'spec' )
    unless File.directory?( spec_dir )
      FileUtils.mkdir_p spec_dir
    end

    ext_dir = File.join( target_dir, 'ext', short_name )
    unless File.directory?( ext_dir )
      FileUtils.mkdir_p ext_dir
    end

    structs.each do |struct_class|
      # NB the _class refers to class inside target project, not in current process
      struct_class.write ext_dir
      struct_class.write_user ext_dir
      struct_class.write_specs spec_dir
    end

    true
  end

  private

  # Writes project files copied from a template directory.
  # @param [String] source_dir template folder that files are recursively copied from.
  # @param [String] target_dir folder where files will be copied to. New files will be written, existing files are skipped.
  # @option source_names [String] :source_short_name, name used in template project file names and content, will be globally replaced
  # @option source_names [String] :source_module_name, namespace used in template project content, will be globally replaced
  # @return [true]
  #
  def copy_project source_dir, target_dir, source_names = { source_short_name: 'kaggle_skeleton', source_module_name: 'KaggleSkeleton' }
    raise "No source project in #{source_dir}" unless File.directory?( source_dir ) && File.exists?( File.join( source_dir, 'Gemfile' ) )
    FileUtils.mkdir_p target_dir
    Dir.glob( File.join( source_dir, '**', '*' ) ) do |source_file|
      copy_project_file source_file, source_dir, target_dir, source_names
    end
    true
  end

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
      render_and_overwrite_template( target_file )
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
    return true if rel_source_file =~ /\.DS_Store\z/
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

  def render_and_overwrite_template target_file
    erb = ERB.new( File.read( target_file ), 0, '-' )
    rendering = erb.result( binding )
    File.open( target_file, 'w' ) { |file| file.puts rendering }
  end
end
