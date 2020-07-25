# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crow/version'

Gem::Specification.new do |spec|
  spec.name          = 'crow'
  spec.version       = Crow::VERSION
  spec.authors       = ['Neil Slater']
  spec.email         = ['slobo777@gmail.com']

  spec.summary       = 'C Ruby Object Writer. Rake utilities for drudge work parts of writing C extensions.'
  spec.homepage      = 'http://github.com/neilslater/crow'
  spec.license       = 'MIT'

  spec.add_dependency 'narray', '>= 0.6.0.8'
  spec.add_dependency 'rake-compiler', '>= 0.8.3'

  spec.add_development_dependency 'bundler', '>= 1.8'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '>= 2.13.0'
  spec.add_development_dependency 'simplecov', '>= 0.18.5'
  spec.add_development_dependency 'bundle-audit', '>= 0.1.0'
  spec.add_development_dependency 'rubocop', '>= 0.83.0'
  spec.add_development_dependency 'yard', '>= 0.9.25'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|gem)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
