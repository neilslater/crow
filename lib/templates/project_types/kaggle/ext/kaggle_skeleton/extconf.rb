# ext/kaggle_skeleton/extconf.rb
# frozen_string_literal: true

require 'mkmf'
require 'numo/narray/alt'

$LOAD_PATH.each do |load_path|
  next unless File.exist?(File.join(load_path, 'numo/numo/narray.h'))

  $INCFLAGS = "-I#{File.join(load_path, 'numo')} #{$INCFLAGS}"
  break
end

abort 'numo/narray.h not found' unless have_header('numo/narray.h')

if RUBY_PLATFORM.include?('darwin') && try_link('int main(void) { return 0; }', '-Wl,-undefined,dynamic_lookup')
  $LDFLAGS << ' -Wl,-undefined,dynamic_lookup'
end

# Manipulations of $srcs and $VPATH allow source files to be organised
SUBDIRS = %w[base util ruby lib].freeze

Dir.chdir(__dir__) do
  $srcs = Dir.glob('*.c') + SUBDIRS.flat_map { |sd| Dir.glob("#{sd}/*.c") }
end

SUBDIRS.each do |sd|
  $VPATH << "$(srcdir)/#{sd}"
end

create_makefile('kaggle_skeleton/kaggle_skeleton')
