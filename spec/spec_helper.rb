# frozen_string_literal: true

require 'bundler/setup'
require 'rspec-puppet'
require 'open3'

# extract the below from spec_helper, as we can't use newer versions puppetlabs_spec_helper due to conflicting ruby versions in
# dependencies
spec_path = File.expand_path(File.join(Dir.pwd, 'spec'))
fixture_path = File.join(spec_path, 'fixtures')

env_module_path = ENV.fetch('MODULEPATH', nil)
module_path = File.join(fixture_path, 'modules')

module_path = [module_path, env_module_path].join(File::PATH_SEPARATOR) if env_module_path

if ENV['SIMPLECOV'] == 'yes'
  begin
    require 'simplecov'
    require 'simplecov-console'

    SimpleCov.formatters = [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console
    ]

    SimpleCov.start do
      track_files 'lib/**/*.rb'
      add_filter '/spec'

      add_filter 'lib/puppet/resource_api/version.rb'

      # do not track vendored files
      add_filter '/vendor'
      add_filter '/.vendor'
    end
  rescue LoadError
    raise 'Add the simplecov and simplecov-console gems to Gemfile to enable this task'
  end
end

# Add all spec lib dirs to LOAD_PATH
components = module_path.split(File::PATH_SEPARATOR).map do |dir|
  next unless Dir.exist? dir

  Dir.entries(dir).grep_v(/^\./).map { |f| File.join(dir, f, 'spec', 'lib') }
end
components.compact.flatten.each do |d|
  $LOAD_PATH << d if FileTest.directory?(d) && !$LOAD_PATH.include?(d)
end

RSpec.configure do |config|
  # override legacy default from puppetlabs_spec_helper
  config.mock_with :rspec

  # enable rspec-puppet support everywhere
  config.include RSpec::Puppet::Support

  # reset the warning suppression count
  config.before do
    Puppet::ResourceApi.warning_count = 0
  end
  config.formatter = 'RSpec::Github::Formatter' if ENV['GITHUB_ACTIONS'] == 'true'

  config.environmentpath = spec_path
  config.module_path = module_path

  # https://github.com/puppetlabs/rspec-puppet#strict_variables
  config.strict_variables = ENV['STRICT_VARIABLES'] != 'no'
  # https://github.com/puppetlabs/rspec-puppet#ordering
  config.ordering = ENV['ORDERING'] if ENV['ORDERING']

  config.before do
    if config.mock_framework.framework_name == :rspec
      allow(Puppet.features).to receive(:root?).and_return(true)
    else
      Puppet.features.stubs(:root?).returns(true)
    end
  end
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
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
