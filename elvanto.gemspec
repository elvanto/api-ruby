# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elvanto/version'

Gem::Specification.new do |spec|
  spec.name          = "elvanto-api"
  spec.version       = ElvantoAPI::VERSION
  spec.authors       = ["Elvanto"]
  spec.email         = ["support@elvanto.com"]
  spec.summary       = %q{Ruby wrapper for Elvanto API}
  spec.description   = %q{API wrapper for use in conjunction with an Elvanto account. This wrapper can be used by developers to develop programs for their own churches using an API Key, or to design integrations to share to other churches using OAuth authentication.}
  spec.homepage      = "https://www.elvanto.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency("faraday", ['>= 0.8.6', '<= 0.9.0'])
  spec.add_dependency("faraday_middleware", '~> 0.9.0')
  spec.add_dependency("addressable", '~> 2.3.5')
end
