# frozen_string_literal: true

if ENV['COVERAGE'] == 'yes'
  begin
    require 'simplecov'
    require 'simplecov-console'

    SimpleCov.formatters = [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console
    ]

    if ENV['CI'] == 'true'
      require 'codecov'
      SimpleCov.formatters << SimpleCov::Formatter::Codecov
    end

    SimpleCov.start do
      track_files 'lib/**/*.rb'

      add_filter '/spec'
      add_filter 'lib/puppet/resource_api/version.rb'
      add_filter '/docs'
      add_filter '/contrib'
      add_filter 'bin/setup'

      # do not track vendored files
      add_filter '/vendor'
      add_filter '/.vendor'
    end
  rescue LoadError
    raise 'Add the simplecov, simplecov-console, codecov gems to Gemfile to enable this task'
  end
end

require 'bundler/setup'
require 'rspec-puppet'
require 'open3'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # override legacy default from puppetlabs_spec_helper
  config.mock_with :rspec

  # enable rspec-puppet support everywhere
  config.include RSpec::Puppet::Support

  # reset the warning suppression count
  config.before do
    Puppet::ResourceApi.warning_count = 0
  end
end

require 'puppet/resource_api'

# configure this hook after Resource API is loaded to get access to Puppet::ResourceApi::Transport
RSpec.configure do |config|
  config.after do
    # reset registered transports between tests to reduce cross-test poisoning
    Puppet::ResourceApi::Transport.instance_variable_set(:@transports, nil)
    if (autoloader = Puppet::ResourceApi::Transport.instance_variable_get(:@autoloader))
      autoloader.class.loaded.clear
    end
  end
end
