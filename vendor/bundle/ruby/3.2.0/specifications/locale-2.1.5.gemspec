# -*- encoding: utf-8 -*-
# stub: locale 2.1.5 ruby lib

Gem::Specification.new do |s|
  s.name = "locale".freeze
  s.version = "2.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kouhei Sutou".freeze, "Masao Mutoh".freeze]
  s.date = "1980-01-02"
  s.description = "Ruby-Locale is the pure ruby library which provides basic APIs for localization.\n".freeze
  s.email = ["kou@clear-code.com".freeze, "mutomasa at gmail.com".freeze]
  s.homepage = "https://github.com/ruby-gettext/locale".freeze
  s.licenses = ["Ruby".freeze, "LGPL-3.0-or-later".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Ruby-Locale is the pure ruby library which provides basic APIs for localization.".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<fiddle>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<kramdown>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
  s.add_development_dependency(%q<test-unit-rr>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
end
