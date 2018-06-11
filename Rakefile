require 'bundler/gem_tasks'
require 'puppetlabs_spec_helper/tasks/fixtures'
require 'parallel_tests'
require 'parallel_tests/cli'
require 'fileutils'

task :default => :spec

#### RUBOCOP ####
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

#### RSPEC ####


require 'rspec/core/rake_task'

if RUBY_PLATFORM == 'java'
  RSpec::Core::RakeTask.new(:spec) do |t|
    Rake::Task[:spec_prep].invoke
    # thanks to the fixtures/modules/ symlinks this needs to exclude fixture modules explicitely
    excludes = ['fixtures/**/*.rb,fixtures/modules/*/**/*.rb', 'acceptance/**/*.rb', 'integration/**/*.rb', 'puppet/resource_api/*_context_spec.rb', 'puppet/util/network_device/simple/device_spec.rb']
    t.rspec_opts = '--tag ~agent_test'
    t.exclude_pattern = "spec/{#{excludes.join ','}}"
  end
else
  desc 'Run RSpec code examples with coverage collection'
  task :spec do
    # perform a puppet apply to initialise puppet up front
    system("bundle exec puppet apply --noop spec/fixtures/manifests/site.pp")
    Rake::Task[:spec_prep].invoke
    args = ['--serialize-stdout', '--combine-stderr', '-t', 'rspec','spec/acceptance','spec/classes','spec/integration','spec/puppet']
    ParallelTests::CLI.new.run(args)
    Rake::Task[:spec_clean].invoke
  end
end

namespace :spec do
  desc 'Run RSpec code examples with coverage collection'
  task :coverage do
    ENV['COVERAGE'] = 'yes'
    FileUtils.rm_rf('coverage')
    Rake::Task['spec'].execute
  end
end

#### LICENSE_FINDER ####
desc 'Check for unapproved licenses in dependencies'
task(:license_finder) do
  system('license_finder --decisions-file=.dependency_decisions.yml') || raise(StandardError, 'Unapproved license(s) found on dependencies')
end

#### CHANGELOG ####
begin
  require 'github_changelog_generator/task'
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    require 'puppet/resource_api/version'
    config.future_release = "v#{Puppet::ResourceApi::VERSION}"
    config.header = "# Changelog\n\n" \
      "All significant changes to this repo will be summarized in this file.\n"
    # config.include_labels = %w[enhancement bug]
    config.user = 'puppetlabs'
    config.project = 'puppet-resource_api'
  end
rescue LoadError
  desc 'Install github_changelog_generator to get access to automatic changelog generation'
  task :changelog do
    raise 'Install github_changelog_generator to get access to automatic changelog generation'
  end
end
