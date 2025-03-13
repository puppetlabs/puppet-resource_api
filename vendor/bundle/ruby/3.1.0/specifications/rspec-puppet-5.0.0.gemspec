# -*- encoding: utf-8 -*-
# stub: rspec-puppet 5.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-puppet".freeze
  s.version = "5.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tim Sharpe".freeze, "Puppet, Inc.".freeze, "Community Contributors".freeze]
  s.date = "2024-09-06"
  s.description = "    RSpec tests for your Puppet manifests.\n".freeze
  s.email = ["tim@sharpe.id.au".freeze, "modules-team@puppet.com".freeze]
  s.executables = ["rspec-puppet-init".freeze]
  s.files = ["bin/rspec-puppet-init".freeze]
  s.homepage = "https://github.com/puppetlabs/rspec-puppet/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "RSpec tests for your Puppet manifests".freeze

  s.installed_by_version = "3.3.27" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rspec>.freeze, ["~> 3.0"])
  else
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
  end
end
