require 'spec_helper'
require 'puppet/resource_api/puppet_logger'

RSpec.describe Puppet::ResourceApi::PuppetLogger do
  subject(:logger) { described_class.new('some_resource') }

  describe '#warning(msg)' do
    it 'calls the Puppet logging infrastructure' do
      expect(Puppet::Util::Logging).to receive(:warning).with(match %r{message})
      logger.warning('message')
    end
  end
end
