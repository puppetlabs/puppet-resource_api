require 'spec_helper'

RSpec.describe Puppet::ResourceApi::PuppetContext do
  subject(:context) { described_class.new(definition) }

  let(:definition) { { name: 'some_resource' } }

  describe '#warning(msg)' do
    it 'calls the Puppet logging infrastructure' do
      expect(Puppet::Util::Log).to receive(:create).with(level: :warning, message: match(%r{message}))
      context.warning('message')
    end
  end
end
