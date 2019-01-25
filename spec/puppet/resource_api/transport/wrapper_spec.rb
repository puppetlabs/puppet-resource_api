require 'spec_helper'
require 'puppet/resource_api/transport/wrapper'
require_relative '../../../fixtures/test_module/lib/puppet/transport/test_device'

RSpec.describe Puppet::ResourceApi::Transport::Wrapper, agent_test: true do
  describe '#initialize(name, url_or_config)' do
    context 'when called with a url' do
      context 'with a file:// prefix' do
        let(:url) { 'file:///etc/credentials' }

        it 'will not throw an error' do
          allow(File).to receive(:exist?).and_return(true)
          expect(Puppet::ResourceApi::Transport).to receive(:connect)
          expect(Hocon).to receive(:load)
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

      it 'will use the configuration directly' do
        expect(Hocon).not_to receive(:load)
        expect(Puppet::ResourceApi::Transport).to receive(:connect)
        described_class.new('wibble', config)
      end
    end
  end

  describe '#facts' do
    context 'when called' do
      let(:instance) { described_class.new('wibble', {}) }
      let(:facts) { { 'foo' => 'bar' } }
      let(:transport) { instance_double(Puppet::Transport::TestDevice, 'transport') }

      it 'will return the facts provided by the transport' do
        allow(Puppet::ResourceApi::Transport).to receive(:connect).and_return(transport)
        allow(transport).to receive(:facts).with(nil).and_return(facts)

        expect(instance.facts).to eq(facts)
      end
    end
  end

  context 'when an unsupported method is called' do
    context 'when the transport can handle the method' do
      let(:instance) { described_class.new('wibble', {}) }
      let(:transport) { instance_double(Puppet::Transport::TestDevice, 'transport') }
      let(:context) { instance_double(Puppet::ResourceApi::PuppetContext, 'context') }

      it 'will return the facts provided by the transport' do
        allow(Puppet::ResourceApi::Transport).to receive(:connect).and_return(transport)
        expect(transport).to receive(:close)

        instance.close(context)
      end
    end

    context 'when the transport cannot handle the method' do
      let(:instance) { described_class.new('wibble', {}) }
      let(:transport) { instance_double(Puppet::Transport::TestDevice, 'transport') }

      it 'will raise a NoMethodError' do
        allow(Puppet::ResourceApi::Transport).to receive(:connect).and_return(transport)
        expect { instance.wibble }.to raise_error NoMethodError
      end
    end
  end

  context 'when a method is checked for' do
    let(:instance) { described_class.new('wibble', {}) }
    let(:transport) { instance_double(Puppet::Transport::TestDevice, 'transport') }

    before(:each) do
      allow(Puppet::ResourceApi::Transport).to receive(:connect).and_return(transport)
    end

    context 'when the transport does not support the function' do
      context 'when using respond_to?' do
        it 'will return false' do
          expect(instance.respond_to?(:wibble)).to eq(false)
        end
      end

      context 'when using method?' do
        it 'will return false' do
          expect { instance.method :wibble }.to raise_error
        end
      end
    end

    context 'when the transport does support the function' do
      before(:each) do
        allow(transport).to receive(:close)
      end

      context 'when using respond_to?' do
        it 'will return true' do
          expect(instance.respond_to?(:close)).to eq(true)
        end
      end

      context 'when using method?' do
        it 'will return the method' do
          expect(instance.method(:close)).to be_a(Method)
        end
      end
    end
  end
end
