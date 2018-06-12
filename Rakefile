require 'bundler/gem_tasks'
require 'puppetlabs_spec_helper/tasks/fixtures'
require 'parallel_tests'
require 'parallel_tests/cli'
require 'fileutils'

if RUBY_PLATFORM != 'java'
  task :default => [:spec, :'spec:acceptance']
else
  task :default => :spec
end

#### RUBOCOP ####
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

#### RSPEC ####
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  Rake::Task[:spec_prep].invoke
  ENV['COVERAGE'] = 'yes'
  FileUtils.rm_rf('coverage')
  # thanks to the fixtures/modules/ symlinks this needs to exclude fixture modules explicitely
  excludes = ['fixtures/**/*.rb','fixtures/modules/*/**/*.rb','acceptance/**/*.rb']
  if RUBY_PLATFORM == 'java'
    excludes += ['integration/**/*.rb', 'puppet/resource_api/*_context_spec.rb', 'puppet/util/network_device/simple/device_spec.rb']
    t.rspec_opts = '--tag ~agent_test'
  end
  t.exclude_pattern = "spec/{#{excludes.join ','}}"
end

namespace :spec do
  if RUBY_PLATFORM != 'java'
    desc 'Run RSpec acceptance tests in parrallel'
    task :parallel do
      ENV.delete('COVERAGE') if ENV.key? 'COVERAGE'
      # perform a puppet apply to initialise puppet up front
      system("bundle exec puppet apply --noop spec/fixtures/manifests/site.pp")
      Rake::Task[:spec_prep].invoke
      args = ['--serialize-stdout', '--combine-stderr', '-t', 'rspec','spec/acceptance']
      ParallelTests::CLI.new.run(args)
      Rake::Task[:spec_clean].invoke
    end
  end

  RSpec::Core::RakeTask.new(:acceptance) do |t|
    ENV.delete('COVERAGE') if ENV.key? 'COVERAGE'
    Rake::Task[:spec_prep].invoke
    excludes = ['fixtures/**/*.rb','fixtures/modules/*/**/*.rb']
    t.rspec_opts = '--tag ~agent_test --pattern spec/acceptance/*.rb'
    t.exclude_pattern = "spec/{#{excludes.join ','}}"
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
