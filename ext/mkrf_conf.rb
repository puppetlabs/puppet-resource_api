# Based on the example from https://en.wikibooks.org/wiki/Ruby_Programming/RubyGems#How_to_install_different_versions_of_gems_depending_on_which_version_of_ruby_the_installee_is_using
require 'rubygems'
require 'rubygems/command.rb'
require 'rubygems/dependency_installer.rb'
begin
  Gem::Command.build_args = ARGV
rescue NoMethodError # rubocop:disable Lint/HandleExceptions
end
inst = Gem::DependencyInstaller.new
begin
  if RbConfig::CONFIG['host_os'] =~ %r{mswin|msys|mingw32}i
    inst.install 'childprocess', '~> 0.7'
  end
rescue StandardError
  exit(1)
end

f = File.open(File.join(File.dirname(__FILE__), 'Rakefile'), 'w') # create dummy rakefile to indicate success
f.write("task :default\n")
f.close
