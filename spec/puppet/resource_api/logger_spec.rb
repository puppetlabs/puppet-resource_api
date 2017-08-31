require 'spec_helper'
require 'puppet/resource_api/io_logger'

RSpec.describe Puppet::ResourceApi::IOLogger do
  subject(:logger) { described_class.new('some_resource', io) }

  let(:io) { StringIO.new('', 'w') }

  describe '#warning(msg)' do
    it 'outputs the message' do
      logger.warning('message')
      expect(io.string).to match %r{message}
    end
    it 'outputs at the correct level' do
      logger.warning('message')
      expect(io.string).to match %r{warning}i
    end
  end
end
