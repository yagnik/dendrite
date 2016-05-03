# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dendrite/version'

Gem::Specification.new do |spec|
  spec.name          = "dendrite"
  spec.version       = Dendrite::VERSION
  spec.authors       = ["Yagnik"]
  spec.email         = ["yagnikkhanna@gmail.com"]

  spec.summary       = "Build config files for synapse and nerve of smartstack"
  spec.description   = "Build config files for synapse and nerve of smartstack"
  spec.homepage      = "https://github.com/yagnik/dendrite"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry", "~> 0"
  spec.add_dependency             "activemodel", "~> 4.2"
end
