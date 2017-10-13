require 'childprocesscore'

module Puppet::ResourceApi
  # A useful interface to safely run system commands
  #
  # See https://github.com/DavidS/puppet-specifications/blob/reasourceapi/language/resource-api/README.md#commands for a complete specification
  class Command
    # Small utility class to hold the `run()` results together
    class Result
      attr_accessor :stdout, :stderr, :exit_code
      def initialize
        @stdout = ''
        @stderr = ''
      end
    end

    attr_accessor :cwd, :environment

    attr_reader :command

    def initialize(command)
      @command = command
      @cwd = '/'
      @environment = {}
    end

    def run(context, *args,
            stdin_source: :none, stdin_value: nil, stdin_io: nil,
            stdout_destination: :log, stdout_loglevel: :debug,
            stderr_destination: :log, stderr_loglevel: :warning,
            noop: false)
      raise ArgumentError, "context is a '#{context.class}', expected a 'Puppet::ResourceApi::BaseContext'" unless context.is_a? Puppet::ResourceApi::BaseContext
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

      result = Result.new

      # TODO: https://tickets.puppetlabs.com/browse/PDK-542 - capture/buffer full lines
      while process.alive? || !stdout_r.eof? || !stderr_r.eof?
        rs, _ws, _errs = IO.select([stdout_r, stderr_r])
        rs.each do |pipe|
          loglevel = if pipe == stdout_r
                       stdout_loglevel
                     else
                       stderr_loglevel
                     end

          destination = if pipe == stdout_r
                          stdout_destination
                        else
                          stderr_destination
                        end

          begin
            chunk = pipe.read_nonblock(1024)
            case destination
            when :log
              chunk.split("\n").each { |l| context.send(loglevel, l.strip) }
            when :store
              if pipe == stdout_r
                result.stdout += chunk
              else
                result.stderr += chunk
              end
            end
          rescue Errno::EBADF # rubocop:disable Lint/HandleExceptions
            # This can be thrown on Windows after the process has gone away
            # ignore, retry WaitReadable through outer loop
          rescue IO::WaitReadable, EOFError # rubocop:disable Lint/HandleExceptions
            # ignore, retry WaitReadable through outer loop
          end
        end
      end

      result.exit_code = process.wait

      raise Puppet::ResourceApi::CommandExecutionError, 'Command %{command} failed with exit code %{exit_code}' % { command: command, exit_code: result.exit_code } unless result.exit_code.zero?

      result
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
