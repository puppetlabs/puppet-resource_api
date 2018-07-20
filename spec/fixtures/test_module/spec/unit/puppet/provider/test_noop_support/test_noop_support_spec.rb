require 'spec_helper'

# TODO: needs some cleanup/helper to avoid this misery
module Puppet::Provider::TestNoopSupport; end
require 'puppet/provider/test_noop_support/test_noop_support'

RSpec.describe Puppet::Provider::TestNoopSupport::TestNoopSupport do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  describe '#get' do
    it 'processes resources' do
      expect(provider.get(context)).to eq [
        {
          name: 'foo',
          ensure: 'present',
        },
        {
          name: 'bar',
          ensure: 'present',
        },
      ]
    end
  end

  describe '#set' do
    context 'with noop: false' do
      it 'logs' do
        allow(context).to receive(:notice)
        expect(context).to receive(:notice).with('noop: false').once

        provider.set(context, {}, noop: false)
      end
    end
    context 'with noop: true' do
      it 'logs' do
        allow(context).to receive(:notice)
        expect(context).to receive(:notice).with('noop: true').once

        provider.set(context, {}, noop: true)
      end
    end
  end
end
