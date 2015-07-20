require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Crow unit tests"
RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = "spec/*_spec.rb"
  t.verbose = false
end

task :default => [:test]

