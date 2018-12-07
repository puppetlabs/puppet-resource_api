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

  it { expect { described_class.new(nil) }.to raise_error Puppet::DevError, %r{TransportSchemaDef requires definition to be a Hash} }

  describe '#attributes' do
    context 'when type has attributes' do
      it { expect(type.attributes).to be_key(:host) }
      it { expect(type.attributes).to be_key(:user) }
    end
  end
end
