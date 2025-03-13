# -*- encoding: utf-8 -*-
# stub: rubocop-capybara 2.21.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop-capybara".freeze
  s.version = "2.21.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/rubocop/rubocop-capybara/blob/main/CHANGELOG.md", "documentation_uri" => "https://docs.rubocop.org/rubocop-capybara/", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yudai Takada".freeze]
  s.date = "2024-06-08"
  s.description = "Code style checking for Capybara test files (RSpec, Cucumber, Minitest).\nA plugin for the RuboCop code style enforcing & linting tool.\n".freeze
  s.extra_rdoc_files = ["MIT-LICENSE.md".freeze, "README.md".freeze]
  s.files = ["MIT-LICENSE.md".freeze, "README.md".freeze]
  s.homepage = "https://github.com/rubocop/rubocop-capybara".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "Code style checking for Capybara test files".freeze

  s.installed_by_version = "3.3.27" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rubocop>.freeze, ["~> 1.41"])
  else
    s.add_dependency(%q<rubocop>.freeze, ["~> 1.41"])
  end
end
