# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'matsuri/version'

Gem::Specification.new do |spec|
  spec.name          = "matsuri"
  spec.version       = Matsuri::VERSION
  spec.authors       = ["Ho-Sheng Hsiao"]
  spec.email         = ["hosh@legal.io"]

  spec.summary       = %q{Build a dev environment using Docker and Kubernetes}
  spec.description   = %q{Framework and toolkit to build a dev environment using Docker and Kubernetes}
  spec.homepage      = "https://github.com/matsuri-rb/matsuri"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'thor'
  spec.add_dependency 'mixlib-shellout'
  spec.add_dependency 'mixlib-config'
  spec.add_dependency 'rlet', '~> 0.7.0'
  spec.add_dependency 'map'
  spec.add_dependency 'hashdiff'
  spec.add_dependency 'activesupport', '~> 4.2.3'
  spec.add_dependency 'rainbow'
  spec.add_dependency 'unit', '~> 0.5.0'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
