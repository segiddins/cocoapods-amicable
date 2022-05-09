# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-amicable'
  spec.version       = File.read(File.expand_path('VERSION', __dir__))
  spec.authors       = ['Samuel Giddins']
  spec.email         = ['segiddins@segiddins.me']
  spec.summary       = 'A CocoaPods plugin that moves the Podfile checksum to a file in the Sandbox, ' \
                       "reducing merge conflicts for teams that don't commit their Pods directory."
  spec.homepage      = 'https://github.com/segiddins/cocoapods-amicable'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'

  spec.required_ruby_version = '~> 3.1.0'
end
