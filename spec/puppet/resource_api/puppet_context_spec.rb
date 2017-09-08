require 'spec_helper'
require 'puppet/resource_api/puppet_context'

RSpec.describe Puppet::ResourceApi::PuppetContext do
  subject(:context) { described_class.new('some_resource') }

  describe '#warning(msg)' do
    it 'calls the Puppet logging infrastructure' do
      expect(Puppet::Util::Logging).to receive(:warning).with(match %r{message})
      context.warning('message')
    end
  end
end
