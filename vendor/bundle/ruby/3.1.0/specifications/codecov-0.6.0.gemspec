# -*- encoding: utf-8 -*-
# stub: codecov 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "codecov".freeze
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/codecov/codecov-ruby/issues", "changelog_uri" => "https://github.com/codecov/codecov-ruby/blob/v0.6.0/CHANGELOG.md", "documentation_uri" => "http://www.rubydoc.info/gems/codecov/0.6.0", "homepage_uri" => "https://github.com/codecov/codecov-ruby", "source_code_uri" => "https://github.com/codecov/codecov-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steve Peak".freeze, "Tom Hu".freeze]
  s.date = "2021-08-18"
  s.description = "Hosted code coverage Ruby reporter.".freeze
  s.email = ["hello@codecov.io".freeze]
  s.homepage = "https://github.com/codecov/codecov-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 2.4".freeze, "< 4".freeze])
  s.rubygems_version = "3.3.27".freeze
  s.summary = "Hosted code coverage".freeze

  s.installed_by_version = "3.3.27" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<simplecov>.freeze, [">= 0.15", "< 0.22"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_development_dependency(%q<mocha>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<webmock>.freeze, ["~> 3.0"])
  else
    s.add_dependency(%q<simplecov>.freeze, [">= 0.15", "< 0.22"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 1.0"])
    s.add_dependency(%q<webmock>.freeze, ["~> 3.0"])
  end
end
