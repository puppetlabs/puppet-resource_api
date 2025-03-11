# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock

require 'spec_helper'
require 'puppet/resource_api/transport/wrapper'
require_relative '../../../fixtures/test_module/lib/puppet/transport/test_device'

RSpec.describe Puppet::ResourceApi::Transport::Wrapper, agent_test: true do
  describe '#initialize(name, url_or_config)' do
    before do
      module Puppet::Transport
        class SomethingSomethingDarkside; end
      end
    end

    context 'when called with a url' do
      context 'with a file:// prefix' do
        let(:url) { 'file:///etc/credentials' }

        it 'does not throw an error' do
          allow(File).to receive(:exist?).and_return(true)
          allow(Hocon).to receive(:load).and_call_original
          expect(Puppet::ResourceApi::Transport).to receive(:connect)
          allow(Hocon).to receive(:load).with('/etc/credentials', any_args).and_return('foo' => %w[a b], 'bar' => 2)
          expect(Hocon).to receive(:load).with('/etc/credentials', any_args)
          expect { described_class.new('wibble', url) }.not_to raise_error
        end
      end

      context 'with an http:// prefix' do
        let(:url) { 'http://www.puppet.com' }

        it { expect { described_class.new('wibble', url) }.to raise_error RuntimeError, %r{Only file:/// URLs for configuration supported} }
      end
    end

    context 'when called with a config hash' do
      let(:config) { {} }

      it 'uses the configuration directly' do
        allow(Hocon).to receive(:load).and_call_original
        expect(Hocon).not_to receive(:load).with('/etc/credentials', any_args)
        expect(Puppet::ResourceApi::Transport).to receive(:connect)
        described_class.new('wibble', config)
      end
    end

    context 'when called with a transport class' do
      let(:transport) { Puppet::Transport::SomethingSomethingDarkside.new }
      let(:instance) { described_class.new('something_something_darkside', transport) }

      it 'sets the @transport class variable' do
        expect(instance.instance_variable_get(:@transport)).to eq(transport)
      end
    end
  end

  describe '#facts' do
    context 'when called' do
      let(:instance) { described_class.new('wibble', {}) }
      let(:context) { instance_double(Puppet::ResourceApi::PuppetContext, 'context') }
      let(:facts) { { 'foo' => 'bar' } }
      let(:transport) { instance_double(Puppet::Transport::TestDevice, 'transport') }

      it 'returns the facts provided by the transport' do
        allow(Puppet::ResourceApi::Transport).to receive(:connect).and_return(transport)
        allow(Puppet::ResourceApi::Transport).to receive(:list).and_return(schema: :dummy)
        allow(Puppet::ResourceApi::PuppetContext).to receive(:new).and_return(context)
        allow(transport).to receive(:facts).with(context).and_return(facts)

        expect(instance.facts).to eq(facts)
      end
    end
  end

  context 'when an unsupported method is called' do
    context 'when the transport can handle the method' do
      let(:instance) { described_class.new('wibble', {}) }
      let(:transport) { instance_double(Puppet::Transport::TestDevice, 'transport') }
      let(:context) { instance_double(Puppet::ResourceApi::PuppetContext, 'context') }

      it 'returns the facts provided by the transport' do
        allow(Puppet::ResourceApi::Transport).to receive(:connect).and_return(transport)
        expect(transport).to receive(:close)

        instance.close(context)
      end
    end

    context 'when the transport cannot handle the method' do
      let(:instance) { described_class.new('wibble', {}) }
      let(:transport) { instance_double(Puppet::Transport::TestDevice, 'transport') }

      it 'raises a NoMethodError' do
        allow(Puppet::ResourceApi::Transport).to receive(:connect).and_return(transport)
        expect { instance.wibble }.to raise_error NoMethodError
      end
    end
  end

  context 'when a method is checked for' do
    let(:instance) { described_class.new('wibble', {}) }
    let(:transport) { instance_double(Puppet::Transport::TestDevice, 'transport') }

    before do
      allow(Puppet::ResourceApi::Transport).to receive(:connect).and_return(transport)
    end

    context 'when the transport does not support the function' do
      context 'when using respond_to?' do
        it 'returns false' do
          expect(instance.respond_to?(:wibble)).to be(false)
        end
      end

      context 'when using method?' do
        it 'returns false' do
          expect { instance.method :wibble }.to raise_error NameError, /undefined method `wibble'/
        end
      end
    end

    context 'when the transport does support the function' do
      before do
        allow(transport).to receive(:close)
      end

      context 'when using respond_to?' do
        it 'returns true' do
          expect(instance.respond_to?(:close)).to be(true)
        end
      end

      context 'when using method?' do
        it 'returns the method' do
          expect(instance.method(:close)).to be_a(Method)
        end
      end
    end
  end
end

# rubocop:enable Lint/ConstantDefinitionInBlock
