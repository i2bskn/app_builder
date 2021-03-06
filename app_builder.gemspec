
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "app_builder/version"

Gem::Specification.new do |spec|
  spec.name          = "app_builder"
  spec.version       = AppBuilder::VERSION
  spec.authors       = ["i2bskn"]
  spec.email         = ["i2bskn@gmail.com"]

  spec.summary       = %q{Application build utilities.}
  spec.description   = %q{Application build utilities.}
  spec.homepage      = "https://github.com/i2bskn/app_builder"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "net-ssh"
  spec.add_dependency "net-scp"
  spec.add_dependency "aws-sdk-s3"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry"
end
