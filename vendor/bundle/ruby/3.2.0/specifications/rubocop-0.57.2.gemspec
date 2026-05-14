# -*- encoding: utf-8 -*-
# stub: rubocop 0.57.2 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop".freeze
  s.version = "0.57.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rubocop-hq/rubocop/issues", "changelog_uri" => "https://github.com/rubocop-hq/rubocop/blob/master/CHANGELOG.md", "documentation_uri" => "https://rubocop.readthedocs.io/", "homepage_uri" => "https://rubocop.readthedocs.io/", "source_code_uri" => "https://github.com/rubocop-hq/rubocop/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bozhidar Batsov".freeze, "Jonas Arvidsson".freeze, "Yuji Nakayama".freeze]
  s.bindir = "exe".freeze
  s.date = "2018-06-12"
  s.description = "    Automatic Ruby code style checking tool.\n    Aims to enforce the community-driven Ruby Style Guide.\n".freeze
  s.email = "rubocop@googlegroups.com".freeze
  s.executables = ["rubocop".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze, "exe/rubocop".freeze]
  s.homepage = "https://github.com/rubocop-hq/rubocop".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Automatic Ruby code style checking tool.".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<jaro_winkler>.freeze, ["~> 1.5.1"])
  s.add_runtime_dependency(%q<parallel>.freeze, ["~> 1.10"])
  s.add_runtime_dependency(%q<parser>.freeze, [">= 2.5"])
  s.add_runtime_dependency(%q<powerpack>.freeze, ["~> 0.1"])
  s.add_runtime_dependency(%q<rainbow>.freeze, [">= 2.2.2", "< 4.0"])
  s.add_runtime_dependency(%q<ruby-progressbar>.freeze, ["~> 1.7"])
  s.add_runtime_dependency(%q<unicode-display_width>.freeze, ["~> 1.0", ">= 1.0.1"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<rack>.freeze, [">= 1.6.9", "< 2.0"])
end
