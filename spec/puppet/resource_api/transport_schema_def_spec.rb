require 'spec_helper'

RSpec.describe Puppet::ResourceApi::TransportSchemaDef do
  subject(:type) { described_class.new(definition) }

  let(:definition) do
    { name: 'some_target',
      connection_info: {
        host:        {
          type:      'String',
          desc:      'The IP address or hostname',
        },
        user:        {
          type:      'String',
          desc:      'The user to connect as',
        },
      } }
  end

  it { expect { described_class.new(nil) }.to raise_error Puppet::DevError, %r{TransportSchemaDef must be a Hash} }

  describe '#attributes' do
    context 'when type has attributes' do
      it { expect(type.attributes).to be_key(:host) }
      it { expect(type.attributes).to be_key(:user) }
    end
  end

  describe '#validate' do
    context 'when resource is missing attributes' do
      let(:resource) { {} }

      it 'raises an error listing the missing attributes' do
        expect { type.validate(resource) }.to raise_error Puppet::ResourceError, %r{host}
        expect { type.validate(resource) }.to raise_error Puppet::ResourceError, %r{user}
      end
    end

    context 'when resource has all its attributes' do
      let(:resource) { { host: '1234', user: '4321' } }

      it {  expect { type.validate(resource) }.not_to raise_error }
    end
  end
end
