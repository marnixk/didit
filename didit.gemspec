# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'didit/version'

Gem::Specification.new do |spec|
  spec.name          = "didit"
  spec.version       = Didit::VERSION
  spec.authors       = ["Marnix"]
  spec.email         = ["marnixkok+github@gmail.com"]
  spec.description   = %q{Didit - DI for Ruby}
  spec.summary       = %q{Didit is a simple dependency injection and service locator implementation}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
