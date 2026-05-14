# -*- encoding: utf-8 -*-
# stub: powerpack 0.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "powerpack".freeze
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bozhidar Batsov".freeze]
  s.date = "2020-11-16"
  s.description = "A few useful extensions to core Ruby classes.".freeze
  s.email = ["bozhidar@batsov.com".freeze]
  s.homepage = "https://github.com/bbatsov/powerpack".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "A few useful extensions to core Ruby classes.".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 1.3", "< 3.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
