require 'spec_helper'
require 'puppet/resource_api/io_logger'

RSpec.describe Puppet::ResourceApi::BaseLogger do
  class TestLogger < described_class
    attr_reader :last_level, :last_message
    def send_log(l, m)
      @last_level = l
      @last_message = m
    end
  end

  subject(:logger) do
    TestLogger.new('some_resource')
  end

  describe '#warning(msg)' do
    it 'outputs the message' do
      logger.warning('message')
      expect(logger.last_message).to eq 'some_resource: message'
    end
    it 'outputs at the correct level' do
      logger.warning('message')
      expect(logger.last_level).to eq :warning
    end
  end

  describe '#warning(titles, msg)' do
    it 'formats no titles correctly' do
      logger.warning([], 'message')
      expect(logger.last_message).to eq 'some_resource: message'
    end
    it 'formats an empty title correctly' do
      logger.warning('', 'message')
      expect(logger.last_message).to eq 'some_resource[]: message'
    end
    it 'formats a single title' do
      logger.warning('a', 'message')
      expect(logger.last_message).to eq 'some_resource[a]: message'
    end
    it 'formats multiple titles' do
      logger.warning(%w[a b], 'message')
      expect(logger.last_message).to eq 'some_resource[a, b]: message'
    end
  end
  describe '#warning(msg1, msg2, msg3, ...)' do
    it 'outputs all passed messages' do
      logger.warning('msg1', 'msg2', 'msg3')
      expect(logger.last_message).to eq 'msg1, msg2, msg3'
    end
  end
end
