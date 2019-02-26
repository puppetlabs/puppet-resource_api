require 'spec_helper'
require 'puppet/resource_api/io_context'

RSpec.describe Puppet::ResourceApi::IOContext do
  subject(:context) { described_class.new(definition, io, transport) }

  let(:definition) { { name: 'some_resource', attributes: {} } }
  let(:transport) { nil }

  let(:io) { StringIO.new('', 'w') }

  describe '#warning(msg)' do
    it 'outputs the message' do
      context.warning('message')
      expect(io.string).to match %r{message}
    end
    it 'outputs at the correct level' do
      context.warning('message')
      expect(io.string).to match %r{warning}i
    end
  end

  describe '#transport' do
    it { expect(context.transport).to be_nil }
    context 'when passing in a transport' do
      let(:transport) { instance_double(Object, 'transport') }

      it { expect(context.transport).to eq transport }
    end
  end
end
