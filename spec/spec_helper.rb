require 'bundler/setup'

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

  # reset the warning suppression count
  config.before(:each) do
    Puppet::ResourceApi.warning_count = 0
  end
end

# load puppet spec support and coverage setup before loading our code
require 'puppetlabs_spec_helper/module_spec_helper'
require 'puppet/resource_api'

# exclude the `version.rb` which already gets loaded by bundler via the gemspec, and doesn't need coverage testing anyways.
SimpleCov.add_filter 'lib/puppet/resource_api/version.rb' if ENV['SIMPLECOV'] == 'yes'
