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

    let(:logging_proxy) { instance_double(Puppet::ResourceApi::PuppetContext::LoggingProxy, 'logging_proxy') }

    it 'calls the Puppet logging infrastructure' do
      allow(described_class).to receive(:logging_proxy).with(no_args).and_return(logging_proxy)
      expect(logging_proxy).to receive(:log_exception).with(exception, 'message', trace: true)
      context.log_exception(exception, message: 'message', trace: true)
    end
  end
end
