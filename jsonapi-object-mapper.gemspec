# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "jsonapi-object-mapper/version"

Gem::Specification.new do |spec|
  spec.name          = "jsonapi-object-mapper"
  spec.version       = JsonAPIObjectMapper::VERSION
  spec.authors       = ["George Protacio-Karaszi"]
  spec.email         = ["georgekaraszi@gmail.com"]

  spec.summary       = "Digests JSON-API responses to plain old ruby objects"
  spec.description   = "Digests JSON-API responses to plain old ruby objects"
  spec.homepage      = "https://github.com/GeorgeKaraszi/jsonapi-object-mapper"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split("\n").reject { |file| file.start_with?("bin/") }
  spec.test_files    = `git ls-files -- spec/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "oj", "~> 3.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end