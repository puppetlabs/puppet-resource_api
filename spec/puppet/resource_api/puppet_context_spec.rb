require 'spec_helper'

RSpec.describe Puppet::ResourceApi::PuppetContext do
  subject(:context) { described_class.new(definition) }

  let(:definition) { { name: 'some_resource' } }

  describe '#warning(msg)' do
    it 'calls the Puppet logging infrastructure' do
      expect(Puppet::Util::Log).to receive(:create).with(level: :warning, message: match(%r{message}))
      context.warning('message')
    end
  end

  describe '#log_exception(exception, message:, trace:)' do
    let(:exception) do
      ex = ArgumentError.new('x')
      ex.set_backtrace %w[a b c]
      ex
    end

    it 'will log message at error level and with trace' do
      expect(Puppet::Util::Log).to receive(:create).with(level: :err, message: "some_resource: message: x\na\nb\nc")
      context.log_exception(exception, message: 'message', trace: true)
    end

    it 'will log message at error level and without trace' do
      expect(Puppet::Util::Log).to receive(:create).with(level: :err, message: 'some_resource: message: x')
      context.log_exception(exception, message: 'message', trace: false)
    end

    context 'when Puppet[:trace] is enabled' do
      before(:each) do
        allow(Puppet).to receive(:[]).and_call_original
        allow(Puppet).to receive(:[]).with(:trace).and_return(true)
      end

      it 'will log message at error level and with trace,' do
        expect(Puppet::Util::Log).to receive(:create).with(level: :err, message: "some_resource: message: x\na\nb\nc")
        context.log_exception(exception, message: 'message', trace: false)
      end
    end

    context 'when Puppet[:trace] is disabled' do
      before(:each) do
        allow(Puppet).to receive(:[]).and_call_original
        allow(Puppet).to receive(:[]).with(:trace).and_return(false)
      end

      it 'will log message at error level and without trace,' do
        expect(Puppet::Util::Log).to receive(:create).with(level: :err, message: 'some_resource: message: x')
        context.log_exception(exception, message: 'message', trace: false)
      end
    end
  end
end
