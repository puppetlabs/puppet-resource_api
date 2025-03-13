# -*- encoding: utf-8 -*-
# stub: puppet 8.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "puppet".freeze
  s.version = "8.10.0"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Puppet Labs".freeze]
  s.date = "2012-08-17"
  s.description = "Puppet, an automated administrative engine for your Linux, Unix, and Windows systems, performs administrative tasks\n(such as adding users, installing packages, and updating server configurations) based on a centralized specification.\n".freeze
  s.email = "info@puppetlabs.com".freeze
  s.executables = ["puppet".freeze]
  s.files = ["bin/puppet".freeze]
  s.homepage = "https://github.com/puppetlabs/puppet".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rdoc_options = ["--title".freeze, "Puppet - Configuration Management".freeze, "--main".freeze, "README".freeze, "--line-numbers".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "Puppet, an automated configuration management tool".freeze

  s.installed_by_version = "3.3.27" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<deep_merge>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<facter>.freeze, [">= 4.3.0", "< 5"])
    s.add_runtime_dependency(%q<fast_gettext>.freeze, [">= 2.1", "< 4"])
    s.add_runtime_dependency(%q<getoptlong>.freeze, ["~> 0.2.0"])
    s.add_runtime_dependency(%q<locale>.freeze, ["~> 2.1"])
    s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.13"])
    s.add_runtime_dependency(%q<puppet-resource_api>.freeze, ["~> 1.5"])
    s.add_runtime_dependency(%q<scanf>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<semantic_puppet>.freeze, ["~> 1.0"])
  else
    s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
    s.add_dependency(%q<deep_merge>.freeze, ["~> 1.0"])
    s.add_dependency(%q<facter>.freeze, [">= 4.3.0", "< 5"])
    s.add_dependency(%q<fast_gettext>.freeze, [">= 2.1", "< 4"])
    s.add_dependency(%q<getoptlong>.freeze, ["~> 0.2.0"])
    s.add_dependency(%q<locale>.freeze, ["~> 2.1"])
    s.add_dependency(%q<multi_json>.freeze, ["~> 1.13"])
    s.add_dependency(%q<puppet-resource_api>.freeze, ["~> 1.5"])
    s.add_dependency(%q<scanf>.freeze, ["~> 1.0"])
    s.add_dependency(%q<semantic_puppet>.freeze, ["~> 1.0"])
  end
end
