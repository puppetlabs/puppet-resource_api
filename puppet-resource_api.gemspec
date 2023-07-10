lib = File.expand_path('../lib', __FILE__) # __dir__ not supported on ruby-1.9 # rubocop:disable Style/ExpandPathArguments
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppet/resource_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'puppet-resource_api'
  spec.version       = Puppet::ResourceApi::VERSION
  spec.license       = 'Apache-2.0'
  spec.authors       = ['David Schmitt']
  spec.email         = ['david.schmitt@puppet.com']

  spec.summary       = 'This library provides a simple way to write new native resources for puppet.'
  spec.homepage      = 'https://github.com/puppetlabs/puppet-resource_api'

  base = "#{__dir__}#{File::SEPARATOR}"
  dirs =
    Dir[File.join(__dir__, 'lib/**/*')] +
    Dir[File.join(__dir__, 'docs/**/*')]
  spec.files =
    dirs.select { |path| File.file?(path) }.map { |path| path.sub(base, '') } +
    %w[CHANGELOG.md CONTRIBUTING.md README.md LICENSE NOTICE puppet-resource_api.gemspec]

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'hocon', '>= 1.0'
end
