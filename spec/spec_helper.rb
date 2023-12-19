# frozen_string_literal: true

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

# load puppet spec support and coverage setup before loading our code
require 'puppetlabs_spec_helper/module_spec_helper'
require 'puppet/resource_api'

# exclude the `version.rb` which already gets loaded by bundler via the gemspec, and doesn't need coverage testing anyways.
SimpleCov.add_filter 'lib/puppet/resource_api/version.rb' if ENV['SIMPLECOV'] == 'yes'

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
