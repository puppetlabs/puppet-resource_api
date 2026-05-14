# -*- encoding: utf-8 -*-
# stub: simplecov-console 0.9.5 ruby lib

Gem::Specification.new do |s|
  s.name = "simplecov-console".freeze
  s.version = "0.9.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chetan Sarva".freeze]
  s.date = "2026-02-02"
  s.description = "Simple console output formatter for SimpleCov".freeze
  s.email = "chetan@pixelcop.net".freeze
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "http://github.com/chetan/simplecov-console".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Simple console output formatter".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<terminal-table>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<ansi>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.1"])
  s.add_development_dependency(%q<juwelier>.freeze, [">= 0"])
end
