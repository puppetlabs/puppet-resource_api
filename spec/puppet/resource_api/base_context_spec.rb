require 'spec_helper'

RSpec.describe Puppet::ResourceApi::BaseContext do
  class TestContext < described_class
    attr_reader :last_level, :last_message
    def send_log(l, m)
      @last_level = l
      @last_message = m
    end
  end

  subject(:context) do
    TestContext.new('some_resource')
  end

  describe '#warning(msg)' do
    it 'outputs the message' do
      context.warning('message')
      expect(context.last_message).to eq 'some_resource: message'
    end
    it 'outputs at the correct level' do
      context.warning('message')
      expect(context.last_level).to eq :warning
    end
  end

  describe '#warning(titles, msg)' do
    it 'formats no titles correctly' do
      context.warning([], 'message')
      expect(context.last_message).to eq 'some_resource: message'
    end
    it 'formats an empty title correctly' do
      context.warning('', 'message')
      expect(context.last_message).to eq 'some_resource[]: message'
    end
    it 'formats a single title' do
      context.warning('a', 'message')
      expect(context.last_message).to eq 'some_resource[a]: message'
    end
    it 'formats multiple titles' do
      context.warning(%w[a b], 'message')
      expect(context.last_message).to eq 'some_resource[a, b]: message'
    end
  end
  describe '#warning(msg1, msg2, msg3, ...)' do
    it 'outputs all passed messages' do
      context.warning('msg1', 'msg2', 'msg3')
      expect(context.last_message).to eq 'msg1, msg2, msg3'
    end
  end
end
