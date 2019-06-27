require 'spec_helper'

RSpec.describe 'Resource API Transport integration tests:' do
  describe '#list_all_transports' do
    subject(:transports) { Puppet::ResourceApi::Transport.list_all_transports('rp_env') }

    it 'can be called twice' do
      expect {
        Puppet::ResourceApi::Transport.list_all_transports('rp_env')
        Puppet::ResourceApi::Transport.list_all_transports('rp_env')
      }.not_to raise_error
    end

    it 'loads all transports' do
      expect(transports).to have_key 'test_device'
      expect(transports).to have_key 'test_device_sensitive'
      expect(transports['test_device']).to be_a Puppet::ResourceApi::TransportSchemaDef
      expect(transports['test_device'].definition).to include(name: 'test_device')
    end
  end
end
