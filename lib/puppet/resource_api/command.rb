require 'childprocess'

module Puppet::ResourceApi
  # A useful interface to safely run system commands
  #
  # See https://github.com/DavidS/puppet-specifications/blob/reasourceapi/language/resource-api/README.md#commands for a complete specification
  class Command
    attr_accessor :cwd, :environment

    attr_reader :command

    def initialize(command)
      @command = command
      @cwd = '/'
      @environment = {}
    end

    def run(context, *args, noop: false)
      return if noop
      process = self.class.prepare_process(context, command, *args, environment: environment, cwd: cwd)
      process.start
      exit_code = process.wait

      raise Puppet::ResourceApi::CommandExecutionError, 'Command %{command} failed with exit code %{exit_code}' % { command: command, exit_code: exit_code } unless exit_code.zero?
    rescue ChildProcess::LaunchError => e
      raise Puppet::ResourceApi::CommandNotFoundError, 'Error when executing %{command}: %{error}' % { command: command, error: e.to_s }
    end

    def self.prepare_process(_context, command, *args, environment:, cwd:)
      process = ChildProcess.build(command, *args)
      environment.each do |k, v|
        process.environment[k] = v
      end
      process.cwd = cwd

      process
    end
  end
end
