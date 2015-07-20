# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crow/version'

Gem::Specification.new do |spec|
  spec.name          = "crow"
  spec.version       = Crow::VERSION
  spec.authors       = ["Neil Slater"]
  spec.email         = ["slobo777@gmail.com"]

  spec.summary       = %q{C Ruby Object Writer. Rake utilities for drudge work parts of writing C extensions.}
  spec.homepage      = "http://github.com/neilslater/crow"
  spec.license       = "MIT"

  spec.add_development_dependency "yard", ">= 0.8.7.2"
  spec.add_development_dependency "bundler", ">= 1.8"
  spec.add_development_dependency "rspec", ">= 2.13.0"
  spec.add_development_dependency "rake", ">= 10.0.1"
  spec.add_development_dependency "coveralls", ">= 0.6.7"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
