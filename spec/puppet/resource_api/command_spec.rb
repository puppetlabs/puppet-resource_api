require 'spec_helper'

RSpec.describe Puppet::ResourceApi::Command do
  subject(:command) { described_class.new 'commandname' }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:process) { instance_double('ChildProcess::AbstractProcess', 'process') }
  let(:args) { [] }
  let(:io) { instance_double('ChildProcess::AbstractIO', 'io') }
  let(:stdin) { instance_double('IO', 'stdin') }
  let(:stdout) { instance_double('IO', 'stdout') }
  let(:stderr) { instance_double('IO', 'stderr') }

  before(:each) do
    allow(ChildProcess).to receive(:build).with('commandname', *args).and_return(process)
    allow(process).to receive(:cwd=)
    allow(process).to receive(:duplex=)
    allow(process).to receive(:start)
    allow(process).to receive(:wait).and_return(0)
    allow(process).to receive(:alive?).and_return(false)

    allow(process).to receive(:io).and_return(io)
    allow(io).to receive(:stdin).and_return(stdin)
    allow(stdin).to receive(:close)

    stdout_w = instance_double('IO', 'stdout_w')
    stderr_w = instance_double('IO', 'stderr_w')
    allow(IO).to receive(:pipe).and_return([stdout, stdout_w], [stderr, stderr_w]).twice
    allow(IO).to receive(:select).with([stdout, stderr]).and_return([[], [], []])
    allow(io).to receive(:stdout=).with(stdout_w)
    allow(io).to receive(:stderr=).with(stderr_w)
    allow(stdout_w).to receive(:close)
    allow(stderr_w).to receive(:close)

    allow(stdout).to receive(:eof?).and_return(false, true)
    allow(stderr).to receive(:eof?).and_return(false, true)

    allow(context).to receive(:is_a?).with(Puppet::ResourceApi::BaseContext).and_return(true)
  end

  describe '#initialize(command)' do
    context 'when specifying a command name' do
      it 'remembers the name' do
        expect(command.command).to eq 'commandname'
      end
    end

    context 'when specifying a command path' do
      subject(:command) { described_class.new '/usr/bin/commandname' }

      it 'remembers the path' do
        expect(command.command).to eq '/usr/bin/commandname'
      end
    end
  end

  describe '#environment[]' do
    context 'when the command is created' do
      it { expect(command.environment).to be_empty }
      it { expect(command.environment).to be_a Hash }
      it('takes values') { expect { command.environment['ENVVAR'] = 'value' }.not_to raise_error }
    end

    context 'when executing commands' do
      let(:env) { instance_double('Hash') }

      it 'passes the contents on to the execution environment' do
        expect(process).to receive(:environment).and_return(env)
        expect(env).to receive(:[]=).with('TARGET', 'somevalue')
        command.environment['TARGET'] = 'somevalue'
        command.run(context)
      end
    end
  end

  describe '#cwd' do
    context 'when the command is created' do
      it('defaults to a sane value') { expect(command.cwd).to eq '/' }
    end

    context 'when executing commands' do
      let(:env) { instance_double('Hash') }

      it 'passes the contents on to the execution environment' do
        allow(ChildProcess).to receive(:build).with('commandname').and_return(process)
        expect(process).to receive(:cwd=).with('/tmp')
        allow(process).to receive(:duplex=)
        allow(process).to receive(:start)
        allow(process).to receive(:wait).and_return(0)
        command.cwd = '/tmp'
        command.run(context)
      end
    end
  end

  describe '#run(context, *args, **kwargs)' do
    context 'when running an existing command' do
      context 'when passing no arguments' do
        it('executes the bare command') do
          expect(process).to receive(:start).once
          expect(process).to receive(:wait).once
          expect { command.run(context) }.not_to raise_error
        end

        context 'with noop: true' do
          it('doesn\'t execute the command') do
            expect(process).to receive(:start).never
            expect { command.run(context, noop: true) }.not_to raise_error
          end
        end
      end

      context 'when passing in arguments' do
        let(:args) { %w[firstarg secondarg] }

        it('executes the command with the provided arguments') do
          expect(process).to receive(:start).once
          expect(process).to receive(:wait).once
          expect { command.run(context, 'firstarg', 'secondarg') }.not_to raise_error
        end
        context 'with noop: true' do
          it('doesn\'t execute the command') do
            expect(process).to receive(:start).never
            expect { command.run(context, 'firstarg', 'secondarg', noop: true) }.not_to raise_error
          end
        end
      end
    end

    context 'when trying to run a non-existing command' do
      let(:args) { %w[firstarg secondarg] }

      it('raises a Puppet::ResourceApi::CommandNotFoundError') do
        expect(process).to receive(:start).and_raise(ChildProcess::LaunchError, 'some error message').once
        expect(process).to receive(:wait).never
        expect { command.run(context, 'firstarg', 'secondarg') }.to raise_error Puppet::ResourceApi::CommandNotFoundError, %r{some error message}
      end
      context 'with noop: true' do
        it('doesn\'t raise an error') do
          expect(process).to receive(:start).never
          expect { command.run(context, 'firstarg', 'secondarg', noop: true) }.not_to raise_error
        end
      end
    end

    context 'when running a failing command' do
      it('raises a Puppet::ResourceApi::CommandExecutionError') do
        expect(process).to receive(:wait).and_return(1)
        expect { command.run(context) }.to raise_error Puppet::ResourceApi::CommandExecutionError, %r{exit code 1}
      end

      context 'with noop: true' do
        it('doesn\'t raise an error') do
          expect(process).to receive(:start).never
          expect { command.run(context, noop: true) }.not_to raise_error
        end
      end
    end

    describe 'stdin_source:' do
      describe ':none' do
        it('provides no input to the command') do
          expect(stdin).to receive(:close).once

          command.run(context, stdin_source: :none)
        end
      end
      describe ':value' do
        it('provides the input to the command') do
          expect(stdin).to receive(:write).with('söme_text').once
          expect(stdin).to receive(:close).once

          command.run(context, stdin_source: :value, stdin_value: 'söme_text')
        end
      end
      describe ':io' do
        it('provides the file descriptor as input to the command') do
          expect(stdin).to receive(:write).with('söme_text').once
          expect(stdin).to receive(:close).once

          command.run(context, stdin_source: :io, stdin_io: StringIO.new('söme_text'))
        end
      end

      it 'rejects other values'
    end

    describe 'stdout_destination:' do
      before(:each) do
        allow(process).to receive(:alive?).and_return(true, false)
        allow(IO).to receive(:select).with([stdout, stderr]).and_return([[stdout], [], []])
        # build a little state engine to exercise the line-reassembly in the select loop.
        # the buffer contains a list of chunks that will one by one be returned, until finally
        # EOFError is raised
        stdout_buffer = ["först line\nstdöüt_text", "second part of second line\n", 'last line without EOL']
        allow(stdout).to receive(:read_nonblock).with(1024) {
          raise EOFError, 'end of file' if stdout_buffer.empty?
          stdout_buffer.delete_at(0)
        }
      end

      describe ':log' do
        it 'logs lines to debug by default' do
          expect(context).to receive(:debug).with(%r{först line})
          expect(context).to receive(:debug).with(%r{stdöüt_text})
          expect(context).to receive(:debug).with(%r{second part of second line})
          expect(context).to receive(:debug).with(%r{last line without EOL})

          command.run(context)
        end

        it 'reassembled lines split over multiple reads' do
          pending('Not yet implemented: https://tickets.puppetlabs.com/browse/PDK-542 - capture/buffer full lines')
          allow(context).to receive(:debug)
          expect(context).to receive(:debug).with(%r{först line})
          expect(context).to receive(:debug).with(%r{stdöüt_textsecond part of second line})
          expect(context).to receive(:debug).with(%r{last line without EOL})

          command.run(context)
        end

        context 'when specifying a different loglevel' do
          it 'logs lines as specified' do
            expect(context).to receive(:warning).with(%r{först line})
            expect(context).to receive(:warning).with(%r{stdöüt_text})
            expect(context).to receive(:warning).with(%r{second part of second line})
            expect(context).to receive(:warning).with(%r{last line without EOL})

            command.run(context, stdout_loglevel: :warning)
          end

          it 'rejects invalid values'
        end
      end

      describe ':store' do
        it 'returns the stdout in the result object' do
          result = command.run(context, stdout_destination: :store)
          expect(result.stdout).to eq "först line\nstdöüt_textsecond part of second line\nlast line without EOL"
        end
      end

      it 'rejects invalid values'
    end

    describe 'stderr_destination:' do
      before(:each) do
        allow(process).to receive(:alive?).and_return(true, false)
        allow(IO).to receive(:select).with([stdout, stderr]).and_return([[stderr], [], []])
        # build a little state engine to exercise the line-reassembly in the select loop.
        # the buffer contains a list of chunks that will one by one be returned, until finally
        # EOFError is raised
        stderr_buffer = ["först line\nstdëër_text", "second part of second line\n", 'last line without EOL']
        allow(stderr).to receive(:read_nonblock).with(1024) {
          raise EOFError, 'end of file' if stderr_buffer.empty?
          stderr_buffer.delete_at(0)
        }
      end

      describe ':log' do
        it 'logs lines to warning by default' do
          expect(context).to receive(:warning).with(%r{först line})
          expect(context).to receive(:warning).with(%r{stdëër_text})
          expect(context).to receive(:warning).with(%r{second part of second line})
          expect(context).to receive(:warning).with(%r{last line without EOL})

          command.run(context)
        end

        it 'reassembled lines split over multiple reads' do
          pending('Not yet implemented: https://tickets.puppetlabs.com/browse/PDK-542 - capture/buffer full lines')
          allow(context).to receive(:warning)
          expect(context).to receive(:warning).with(%r{först line})
          expect(context).to receive(:warning).with(%r{stdëër_textsecond part of second line})
          expect(context).to receive(:warning).with(%r{last line without EOL})

          command.run(context)
        end

        context 'when specifying a different loglevel' do
          it 'logs lines as specified' do
            expect(context).to receive(:debug).with(%r{först line})
            expect(context).to receive(:debug).with(%r{stdëër_text})
            expect(context).to receive(:debug).with(%r{second part of second line})
            expect(context).to receive(:debug).with(%r{last line without EOL})

            command.run(context, stderr_loglevel: :debug)
          end

          it 'rejects invalid values'
        end
      end

      describe ':store' do
        it 'returns the stderr in the result object' do
          result = command.run(context, stderr_destination: :store)
          expect(result.stderr).to eq "först line\nstdëër_textsecond part of second line\nlast line without EOL"
        end
      end

      it 'rejects invalid values'
    end

    describe 'stdout_encoding' do
      before(:each) do
        allow(process).to receive(:alive?).and_return(true, false)
        allow(IO).to receive(:select).with([stdout, stderr]).and_return([[stdout], [], []])
        # build a little state engine to exercise the line-reassembly in the select loop.
        # the buffer contains a list of chunks that will one by one be returned, until finally
        # EOFError is raised
        stdout_buffer = ["först\n"]
        allow(stdout).to receive(:read_nonblock).with(1024) {
          raise EOFError, 'end of file' if stdout_buffer.empty?
          stdout_buffer.delete_at(0)
        }
      end
      it 'allows an encoding for the stdout to be specified' do
        allow(context).to receive(:debug)
        allow(io).to receive(:stdout).and_return(stdout)
        allow(stdout).to receive(:external_encoding)
        expect(stdout).to receive(:set_encoding).with(anything, 'ISO 8859-5')
        command.run(context, stdout_destination: :store, stdout_encoding: 'ISO 8859-5')
      end
    end

    describe 'stderr_encoding' do
      before(:each) do
        allow(process).to receive(:alive?).and_return(true, false)
        allow(IO).to receive(:select).with([stdout, stderr]).and_return([[stderr], [], []])
        # build a little state engine to exercise the line-reassembly in the select loop.
        # the buffer contains a list of chunks that will one by one be returned, until finally
        # EOFError is raised
        stderr_buffer = ["först\n"]
        allow(stderr).to receive(:read_nonblock).with(1024) {
          raise EOFError, 'end of file' if stderr_buffer.empty?
          stderr_buffer.delete_at(0)
        }
      end

      it 'allows an encoding for the stdout to be specified' do
        allow(context).to receive(:debug)
        allow(io).to receive(:stderr).and_return(stderr)
        allow(stderr).to receive(:external_encoding)
        expect(stderr).to receive(:set_encoding).with(anything, 'ISO 8859-5')
        command.run(context, stderr_destination: :store, stderr_encoding: 'ISO 8859-5')
      end
    end

    describe 'stdin_encoding' do
      it 'allows an encoding for the stdin to be specified' do
        allow(stdin).to receive(:external_encoding)
        expect(stdin).to receive(:set_encoding).with(anything, 'ISO 8859-5')
        command.run(context, stdin_value: 'först', stdin_encoding: 'ISO 8859-5')
      end
    end
  end
end
