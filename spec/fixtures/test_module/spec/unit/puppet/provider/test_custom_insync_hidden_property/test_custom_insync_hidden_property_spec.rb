require 'spec_helper'

# TODO: needs some cleanup/helper to avoid this misery
module Puppet::Provider::TestCustomInsyncHiddenProperty; end
require 'puppet/provider/test_custom_insync_hidden_property/test_custom_insync_hidden_property'

RSpec.describe Puppet::Provider::TestCustomInsyncHiddenProperty::TestCustomInsyncHiddenProperty do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  describe '#get' do
    it 'processes resources and does not return rsapi_custom_insync_trigger' do
      expect(provider.get(context)).to eq [
        {
          name: 'example'
        }
      ]
    end
  end

  describe 'insync?(context, name, property_name, is_hash, should_hash)' do
    let(:is_hash) { { name: 'example' } }

    before(:each) do
      allow(context).to receive(:notice).with(%r{\AChecking whether rsapi_custom_insync_trigger is out of sync})
    end

    it 'checks insync for rsapi_custom_insync_trigger' do
      expect { provider.insync?(context, 'example', :rsapi_custom_insync_trigger, is_hash, { name: 'example' }) }.not_to raise_error
    end
    it 'returns true if force is not specified as true' do
      expect(provider.insync?(context, 'example', :rsapi_custom_insync_trigger, is_hash, { name: 'example' })).to be true
    end
    it 'returns false if force is specified as true' do
      expect(context).to receive(:notice).with(%r{\AOut of sync!})
      expect(provider.insync?(context, 'example', :rsapi_custom_insync_trigger, is_hash, { name: 'example', force: true })).to be false
    end
  end
end
