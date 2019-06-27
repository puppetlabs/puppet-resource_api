require 'spec_helper'

RSpec.describe 'Resource API Transport integration tests:' do
  after(:each) do
    # reset registered transports between tests to reduce cross-test poisoning
    Puppet::ResourceApi::Transport.instance_variable_set(:@transports, nil)
    autoloader = Puppet::ResourceApi::Transport.instance_variable_get(:@autoloader)
    autoloader.class.loaded.clear
  end

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
