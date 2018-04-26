require 'spec_helper'
require 'puppet/resource_api/io_context'

RSpec.describe Puppet::ResourceApi::IOContext do
  subject(:context) { described_class.new(definition, io) }

  let(:definition) { { name: 'some_resource' } }

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
end
