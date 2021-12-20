# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resource API Transport integration tests:' do
  describe '#list_all_transports' do
    subject(:transports) { Puppet::ResourceApi::Transport.list_all_transports('rp_env') }

    it 'loads all transports' do
      expect(transports).to have_key 'test_device'
      expect(transports).to have_key 'test_device_sensitive'
      expect(transports['test_device']).to be_a Puppet::ResourceApi::TransportSchemaDef
      expect(transports['test_device'].definition).to include(name: 'test_device')
    end

    it 'adds connection_info_order' do
      expect(transports['test_device'].definition).to include(connection_info_order: a_kind_of(Array))
    end

    it 'can be called twice' do
      expect(Puppet::ResourceApi::Transport.list).to be_empty
      Puppet::ResourceApi::Transport.list_all_transports('rp_env')
      expect(Puppet::ResourceApi::Transport.list.length).to eq 3
      Puppet::ResourceApi::Transport.list_all_transports('rp_env')
      expect(Puppet::ResourceApi::Transport.list.length).to eq 3
    end
  end
end
