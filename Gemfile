source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in puppet-resource_api.gemspec
gemspec

group :tests do
  gem 'codecov'
  # license_finder does not install on windows using older versions of rubygems.
  # ruby 2.4 is confirmed working on appveyor.
  gem 'license_finder' if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.4.0')
  gem 'rake', '~> 10.0'
  gem 'rspec', '~> 3.0'
  gem 'rubocop-rspec'
  gem 'rubocop'
  gem 'simplecov-console'
  # the test gems required for module testing
  gem 'puppetlabs_spec_helper', '~> 2.7'
  gem 'rspec-puppet'
end

group :development do
  gem 'github_changelog_generator', '~> 1.14'
  gem 'pry-byebug'
end

# Find a location or specific version for a gem. place_or_version can be a
# version, which is most often used. It can also be git, which is specified as
# `git://somewhere.git#branch`. You can also use a file source location, which
# is specified as `file://some/location/on/disk`.
def location_for(place_or_version, fake_version = nil)
  if place_or_version =~ /^((?:git|https)[:@][^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place_or_version =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place_or_version, { :require => false }]
  end
end

if ENV['PUPPET_GEM_VERSION']
  gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'])
else
  gem 'puppet', github: 'DavidS/puppet', ref: 'device-apply'
end
