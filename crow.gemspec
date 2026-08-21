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

  spec.required_ruby_version = '>= 3.3'

  spec.add_dependency 'numo-narray-alt', '>= 0.9.9', '< 0.12'
  spec.add_dependency 'rake-compiler', '>= 0.8.3'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|gem)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
