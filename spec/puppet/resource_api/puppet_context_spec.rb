# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::ResourceApi::PuppetContext do
  subject(:context) { described_class.new(definition) }

  let(:definition) { { name: 'some_resource', desc: 'a test resource', attributes: {} } }

  describe '#device' do
    context 'when a NetworkDevice is configured' do
      let(:device) { instance_double('Puppet::Util::NetworkDevice::Simple::Device', 'device') }

      before do
        allow(Puppet::Util::NetworkDevice).to receive(:current).and_return(device)
      end

      it 'returns the device' do
        expect(context.device).to eq(device)
      end
    end

    context 'when a Transport::Wrapper device is configured' do
      let(:device) { instance_double('Puppet::Util::NetworkDevice::Test_device::Device', 'device') }
      let(:transport) { instance_double('Puppet::Transport::TestDevice', 'transport') }

      before do
        allow(Puppet::Util::NetworkDevice).to receive(:current).and_return(device)
        allow(device).to receive(:transport).and_return(transport)
      end

      it 'returns the transport' do
        expect(context.transport).to eq(transport)
      end
    end

    context 'with nothing configured' do
      before do
        allow(Puppet::Util::NetworkDevice).to receive(:current).and_return(nil)
      end

      it 'raises an error' do
        expect { context.device }.to raise_error RuntimeError, /no device configured/
      end
    end
  end

  describe '#warning(msg)' do
    it 'calls the Puppet logging infrastructure' do
      expect(Puppet::Util::Log).to receive(:create).with(level: :warning, message: match(/message/))
      context.warning('message')
    end
  end

  describe '#log_exception(exception, message:, trace:)' do
    let(:exception) do
      ex = ArgumentError.new('x')
      ex.set_backtrace %w[a b c]
      ex
    end

    it 'logs message at error level and with trace' do
      expect(Puppet::Util::Log).to receive(:create).with(level: :err, message: "some_resource: message: x\na\nb\nc")
      context.log_exception(exception, message: 'message', trace: true)
    end

    it 'logs message at error level and without trace' do
      expect(Puppet::Util::Log).to receive(:create).with(level: :err, message: 'some_resource: message: x')
      context.log_exception(exception, message: 'message', trace: false)
    end

    context 'when Puppet[:trace] is enabled' do
      before do
        allow(Puppet).to receive(:[]).and_call_original
        allow(Puppet).to receive(:[]).with(:trace).and_return(true)
      end

      it 'logs message at error level and with trace,' do
        expect(Puppet::Util::Log).to receive(:create).with(level: :err, message: "some_resource: message: x\na\nb\nc")
        context.log_exception(exception, message: 'message', trace: false)
      end
    end

    context 'when Puppet[:trace] is disabled' do
      before do
        allow(Puppet).to receive(:[]).and_call_original
        allow(Puppet).to receive(:[]).with(:trace).and_return(false)
      end

      it 'logs message at error level and without trace,' do
        expect(Puppet::Util::Log).to receive(:create).with(level: :err, message: 'some_resource: message: x')
        context.log_exception(exception, message: 'message', trace: false)
      end
    end
  end
end
