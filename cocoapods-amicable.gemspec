# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-amicable/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-amicable'
  spec.version       = CocoapodsAmicable::VERSION
  spec.authors       = ['Samuel Giddins']
  spec.email         = ['segiddins@squareup.com']
  spec.description   = %q{A short description of cocoapods-amicable.}
  spec.summary       = %q{A longer description of cocoapods-amicable.}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-amicable'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
