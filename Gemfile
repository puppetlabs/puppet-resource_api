source 'https://rubygems.org'

# Puppet 9 (and the facter/ffi versions it requires under Ruby 4.0) are not published to public
# RubyGems yet -- resolve them from the private PuppetCore source instead, when a forge token is
# available. Falls back to the default source otherwise (e.g. local dev on the Puppet 8 lane).
# See ruby-pwsh#385 / bolt-private#120 for the established pattern this mirrors.
gemsource_puppetcore = if ENV['PUPPET_FORGE_TOKEN'] && !ENV['PUPPET_FORGE_TOKEN'].empty?
                          'https://rubygems-puppetcore.puppet.com'
                        else
                          ENV['GEM_SOURCE_PUPPETCORE'] || 'https://rubygems.org'
                        end

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in puppet-resource_api.gemspec
gemspec

group :tests do
  gem 'CFPropertyList'
  gem 'rspec', '~> 3.0'
  gem 'simplecov-console'

  # the test gems required for module testing
  # puppetlabs_spec_helper 9.0.0 requires Ruby >= 3.2, which jruby-9.4.2.0 (our Puppet 8 JRuby
  # lane, ~Ruby 3.1 compatible) doesn't satisfy -- keep that lane on 8.0, bump everything else.
  if Gem::Requirement.create('>= 3.2').satisfied_by?(Gem::Version.new(RUBY_VERSION))
    gem 'puppetlabs_spec_helper', '~> 9.0'
  else
    gem 'puppetlabs_spec_helper', '~> 8.0'
  end
  gem 'rspec-puppet'
  gem 'codecov'
  gem 'rake', '~> 13.0'

  # since the Resource API runs inside the puppetserver, test against the JRuby versions we ship
  # these require special dependencies to have everything load properly
  # rubocop 1.48 supports JRuby 9.3+, which includes coverage for versions we support
  gem 'rubocop', '~> 1.73.0', require: false
  gem 'rubocop-rspec', '~> 3.5.0', require: false
  gem 'rubocop-performance', '~> 1.24.0', require: false
  gem 'rubocop-rspec_rails', '~> 2.31.0', require: false
  gem 'rubocop-factory_bot', '~> 2.27.0', require: false
  gem 'rubocop-capybara', '~> 2.22.0', require: false
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
  # Pin due to an issue with FFI, Windows, and Facter. See FACT-3434
  # Bumped from 1.15.5 for Ruby 4.0/Puppet 9 compatibility (see also open dependabot PR #364,
  # which proposed this same bump independently for Puppet 8) -- verify against the actual
  # Puppet 9 gemspec's ffi constraint once available, the public Puppet 8 gemspec still caps at < 1.17.0.
  gem 'ffi', '1.17.1'
end

# Find a location or specific version for a gem. place_or_version can be a
# version, which is most often used. It can also be git, which is specified as
# `git://somewhere.git#branch`. You can also use a file source location, which
# is specified as `file://some/location/on/disk`.
def location_for(place_or_version, fake_version = nil, opts = {})
  if place_or_version =~ /^((?:git|https)[:@][^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place_or_version =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place_or_version, { :require => false }.merge(opts)]
  end
end

# facter is a transitive dependency of puppet's gemspec; bundler resolves it from the same
# PuppetCore remote automatically once puppet itself is pinned there, so no separate pin needed.
gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'], nil, { source: gemsource_puppetcore })
