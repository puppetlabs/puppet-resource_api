require 'spec_helper'

RSpec.describe Puppet::ResourceApi::PuppetContext do
  subject(:context) { described_class.new('some_resource') }

  describe '#warning(msg)' do
    it 'calls the Puppet logging infrastructure' do
      expect(Puppet::ResourceApi::PuppetContext::PuppetLogger).to receive(:send_log).with(:warning, match(%r{message}))
      context.warning('message')
    end
  end
end
