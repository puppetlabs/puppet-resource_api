source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in puppet-resource_api.gemspec
gemspec

group :tests do
  gem 'CFPropertyList'
  gem 'rspec', '~> 3.0'
  gem 'simplecov-console'

  # the test gems required for module testing
  gem 'puppetlabs_spec_helper', '~> 3.0'
  gem 'rspec-puppet'
  gem 'codecov'
  gem 'rake', '~> 13.0'
  gem 'license_finder'

  # since the Resource API runs inside the puppetserver, test against the JRuby versions we ship
  # these require special dependencies to have everything load properly

  # rubocop is special, as usual
  if RUBY_PLATFORM == 'java'
    # load a rubocop version that works on java for the Rakefile
    gem 'parser', '2.3.3.1'
    gem 'rubocop', '0.41.2'
  else
    # 2.1-compatible analysis was dropped after version 0.58
    # This needs to be removed once we drop puppet4 support.
    gem 'rubocop', '~> 0.57.0'
    gem 'rubocop-rspec'
  end
end

group :development do
  gem 'github_changelog_generator', '~> 1.15'
  gem 'pry-byebug'
end

# Starting with version 3.2, Ruby no longer bundles libffi, which is necessary for tests on Windows. Due to a discrepancy between the C
# library the Windows Puppet gem is built against and what GitHub runners use (MinGW and ucrt, respectively) we can't install the Windows-
# specific Puppet gem that includes libffi. To work around these issues, we have a separate "integration" group that we include when
# testing Puppet 8 / Ruby 3.2 on Windows. See PA-5406 for more.
group :integration do
  gem 'ffi'
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

gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'])
