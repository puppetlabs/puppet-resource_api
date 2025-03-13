begin
  require_relative "lib/prime"
rescue LoadError
  # for Ruby core repository
  require_relative "prime"
end

Gem::Specification.new do |spec|
  spec.name          = "prime"
  spec.version       = Prime::VERSION
  spec.authors       = ["Marc-Andre Lafortune"]
  spec.email         = ["ruby-core@marc-andre.ca"]

  spec.summary       = %q{Prime numbers and factorization library.}
  spec.description   = %q{Prime numbers and factorization library.}
  spec.homepage      = "https://github.com/ruby/prime"
  spec.licenses      = ["Ruby", "BSD-2-Clause"]

  spec.files         = ["BSDL", "COPYING", "README.md", "Rakefile", "lib/prime.rb", "prime.gemspec", "sig/integer-extension.rbs", "sig/manifest.yaml", "sig/prime.rbs"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "singleton"
  spec.add_dependency "forwardable"
end
