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

    def run(context, *args,
            stdin_source: :none, stdin_value: nil, stdin_io: nil,
            stdout_loglevel: :debug,
            stderr_loglevel: :warning,
            noop: false)
      return if noop
      process = self.class.prepare_process(context, command, *args, environment: environment, cwd: cwd)

      process.duplex = true

      stdout_r, stdout_w = IO.pipe
      process.io.stdout = stdout_w

      stderr_r, stderr_w = IO.pipe
      process.io.stderr = stderr_w

      process.start
      stdout_w.close
      stderr_w.close

      case stdin_source
      when :none # rubocop:disable Lint/EmptyWhen
        # nothing to do here
      when :io
        while (v = stdin_io.read) && !v.empty? # `empty?` signals EOF, can't use the `length` variant due to encoding issues
          process.io.stdin.write v
        end
      when :value
        process.io.stdin.write stdin_value
      end
      process.io.stdin.close

      # TODO: https://tickets.puppetlabs.com/browse/PDK-542 - capture/buffer full lines
      while process.alive? || !stdout_r.eof? || !stderr_r.eof?
        rs, _ws, _errs = IO.select([stdout_r, stderr_r])
        rs.each do |pipe|
          loglevel = if pipe == stdout_r
                       stdout_loglevel
                     else
                       stderr_loglevel
                     end

          begin
            pipe.read_nonblock(1024).split('\n').each { |l| context.send(loglevel, l.strip) }
          rescue IO::WaitReadable, EOFError
            # ignore, retry WaitReadable through outer loop
          end
        end
      end

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
