require 'spec_helper'

# TODO: needs some cleanup/helper to avoid this misery
module Puppet::Provider::TestBool; end
require 'puppet/provider/test_bool/test_bool'

RSpec.describe Puppet::Provider::TestBool::TestBool do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  describe '#get' do
    it 'processes resources' do
      expect(provider.get(context)).to eq [
        {
          name: 'foo',
          ensure: 'present',
          test_bool: true,
          test_bool_param: true,
        },
        {
          name: 'bar',
          ensure: 'present',
          test_bool: false,
          test_bool_param: false,
        },
      ]
    end
  end

  describe 'create(context, name, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with(%r{\ACreating 'a'})

      provider.create(context, 'a', name: 'a', ensure: 'present')
    end
  end

  describe 'update(context, name, should)' do
    it 'updates the resource' do
      expect(context).to receive(:notice).with(%r{\AUpdating 'foo'})

      provider.update(context, 'foo', name: 'foo', ensure: 'present')
    end
  end

  describe 'delete(context, name, should)' do
    it 'deletes the resource' do
      expect(context).to receive(:notice).with(%r{\ADeleting 'foo'})

      provider.delete(context, 'foo')
    end
  end
end
