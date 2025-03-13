# -*- encoding: utf-8 -*-
# stub: fast_gettext 3.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "fast_gettext".freeze
  s.version = "3.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Grosser".freeze]
  s.date = "2024-08-21"
  s.email = "michael@grosser.it".freeze
  s.homepage = "https://github.com/grosser/fast_gettext".freeze
  s.licenses = ["MIT".freeze, "Ruby".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "A simple, fast, memory-efficient and threadsafe implementation of GetText".freeze

  s.installed_by_version = "3.3.27" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<prime>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.4"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<activerecord>.freeze, [">= 0"])
    s.add_development_dependency(%q<i18n>.freeze, [">= 0"])
    s.add_development_dependency(%q<bump>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop-packaging>.freeze, [">= 0"])
    s.add_development_dependency(%q<single_cov>.freeze, [">= 0"])
    s.add_development_dependency(%q<forking_test_runner>.freeze, [">= 0"])
  else
    s.add_dependency(%q<prime>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1.4"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<activerecord>.freeze, [">= 0"])
    s.add_dependency(%q<i18n>.freeze, [">= 0"])
    s.add_dependency(%q<bump>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop-packaging>.freeze, [">= 0"])
    s.add_dependency(%q<single_cov>.freeze, [">= 0"])
    s.add_dependency(%q<forking_test_runner>.freeze, [">= 0"])
  end
end
