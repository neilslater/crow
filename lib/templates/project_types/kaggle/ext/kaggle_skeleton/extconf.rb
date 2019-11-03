# ext/kaggle_skeleton/extconf.rb
require "mkmf"
require "narray"

# Following code stolen shamelessly from fftw3 gem:
narray_dir = File.dirname(Gem.find_files("narray.h").first) rescue $sitearchdir
dir_config('narray', narray_dir, narray_dir)

if ( ! ( have_header("narray.h") && have_header("narray_config.h") ) ) then
   print <<-EOS
   ** configure error **
   Header narray.h or narray_config.h is not found. If you have these files in
   /narraydir/include, try the following:

   % ruby extconf.rb --with-narray-include=/narraydir/include

EOS
   exit(-1)
end

# This also stolen from fftw3 gem (and not confirmed for Windows platforms - please let me know if it works!)
if /cygwin|mingw/ =~ RUBY_PLATFORM
   have_library("narray") || raise("ERROR: narray library is not found")
end

# Manipulations of $srcs and $VPATH allow source files to be organised
SUBDIRS = ['base', 'util', 'ruby']

Dir.chdir(__dir__) do
   $srcs = Dir.glob('*.c') + SUBDIRS.flat_map { |sd| Dir.glob("#{sd}/*.c") }
end

SUBDIRS.each do |sd|
   $VPATH << "$(srcdir)/#{sd}"
end

create_makefile( 'kaggle_skeleton/kaggle_skeleton' )
