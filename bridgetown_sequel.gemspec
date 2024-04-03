# frozen_string_literal: true

require_relative "lib/bridgetown_sequel/version"

Gem::Specification.new do |spec|
  spec.name          = "bridgetown_sequel"
  spec.version       = BridgetownSequel::VERSION
  spec.author        = "Bridgetown Team"
  spec.email         = "maintainers@bridgetownrb.com"
  spec.summary       = "Bridgetown plugin for integrating the Sequel database gem"
  spec.homepage      = "https://github.com/bridgetownrb/bridgetown_sequel"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|script|spec|features|frontend)/!) }
  spec.test_files    = spec.files.grep(%r!^test/!)
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.1.0"

  spec.add_dependency "bridgetown", ">= 1.3.0"
  spec.add_dependency "sequel", ">= 5.76"
  spec.add_dependency "sequel-annotate", ">= 1.7"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rubocop-bridgetown", "~> 0.3"
end
