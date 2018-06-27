require 'spec_helper'
require 'puppet/util/network_device/simple/device'

RSpec.describe Puppet::Util::NetworkDevice::Simple::Device do
  subject(:device) { described_class.new(url_or_config) }

  context 'when initialized with a file:// URL' do
    context 'when the file exists' do
      let(:tempfile) { Tempfile.new('foo.txt') }
      let(:url_or_config) { 'file://' + tempfile.path }

      before(:each) do
        tempfile.write('{ foo: bar }')
        tempfile.close
      end

      after(:each) { tempfile.unlink }

      it 'provides an empty facts set' do
        expect(device.facts).to eq({})
      end

      it 'provides an array of custom facts' do
        expect(device.return_custom_facts).to eq([])
      end

      it 'makes the configured configuration available' do
        expect(device.config).to eq('foo' => 'bar')
      end

      it 'raises an error, when calling the default add_fact' do
        expect { Puppet::Util::NetworkDevice::Simple::CustomFact.new.add_fact(nil, nil) }.to raise_error RuntimeError, %r{Custom facts must implement this}
      end
    end

    context 'when the file does not exist' do
      let(:url_or_config) { 'file:///tmp/foo.txt' }

      it 'raises an error' do
        expect { device.config }.to raise_error RuntimeError, %r{foo\.txt.*file does not exist}
      end
    end
  end

  context 'when initialized with a non-file:// URL' do
    let(:url_or_config) { 'http://example.com/' }

    it 'raises an error' do
      expect { device }.to raise_error RuntimeError, %r{example.com.*Only file:/// URLs for configuration supported}
    end
  end

  context 'when initialized with a config hash' do
    let(:url_or_config) { { key: :value } }

    it 'makes the configured configuration available' do
      expect(device.config).to eq(key: :value)
    end
  end
end
