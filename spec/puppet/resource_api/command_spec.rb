require 'spec_helper'

RSpec.describe Puppet::ResourceApi::Command do
  subject(:command) { described_class.new 'commandname' }

  let(:context) { nil }
  let(:process) { instance_double('ChildProcess::AbstractProcess') }

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
        allow(ChildProcess).to receive(:build).with('commandname').and_return(process)
        expect(process).to receive(:environment).and_return(env)
        expect(env).to receive(:[]=).with('TARGET', 'somevalue')
        allow(process).to receive(:cwd=)
        allow(process).to receive(:start)
        allow(process).to receive(:wait).and_return(0)
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
        allow(process).to receive(:start)
        allow(process).to receive(:wait).and_return(0)
        command.cwd = '/tmp'
        command.run(context)
      end
    end
  end

  describe '#run(context, *args, noop:)' do
    let(:args) { [] }

    before(:each) do
      allow(ChildProcess).to receive(:build).with('commandname', *args).and_return(process)
      allow(process).to receive(:cwd=)
      allow(process).to receive(:start)
      allow(process).to receive(:wait).and_return(0)
    end

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
  end
end
