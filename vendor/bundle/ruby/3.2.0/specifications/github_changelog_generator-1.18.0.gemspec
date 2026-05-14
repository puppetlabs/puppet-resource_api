# -*- encoding: utf-8 -*-
# stub: github_changelog_generator 1.18.0 ruby lib

Gem::Specification.new do |s|
  s.name = "github_changelog_generator".freeze
  s.version = "1.18.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Petr Korolev".freeze, "Olle Jonsson".freeze, "Marco Ferrari".freeze]
  s.date = "2026-03-18"
  s.description = "Changelog generation has never been so easy. Fully automate changelog generation - this gem generate changelog file based on tags, issues and merged pull requests from GitHub.".freeze
  s.email = "sky4winder+github_changelog_generator@gmail.com".freeze
  s.executables = ["git-generate-changelog".freeze, "github_changelog_generator".freeze]
  s.files = ["bin/git-generate-changelog".freeze, "bin/github_changelog_generator".freeze]
  s.homepage = "https://github.com/github-changelog-generator/github-changelog-generator".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Script that automatically generates a changelog from your tags, issues, labels and pull requests.".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<async>.freeze, [">= 1.25.0"])
  s.add_runtime_dependency(%q<async-http-faraday>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<benchmark>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<faraday-http-cache>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<octokit>.freeze, ["~> 4.6"])
  s.add_runtime_dependency(%q<rainbow>.freeze, [">= 2.2.1"])
  s.add_runtime_dependency(%q<rake>.freeze, [">= 10.0"])
end
