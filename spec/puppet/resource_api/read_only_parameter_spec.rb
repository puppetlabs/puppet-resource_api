require 'spec_helper'

RSpec.describe Puppet::ResourceApi::ReadOnlyParameter do
  subject(:read_only_parameter) do
    described_class.new(name, type, definition, resource)
  end

  let(:definition) { {} }
  let(:log_sink) { [] }
  let(:name) { 'some_parameter' }
  let(:resource) { {} }
  let(:result) { 'value' }
  let(:strict_level) { :error }
  let(:type) { Puppet::Pops::Types::PStringType }
  let(:value) { 'value' }

  before(:each) do
    # set default to strictest setting
    # by default Puppet runs at warning level
    Puppet.settings[:strict] = strict_level
    # Enable debug logging
    Puppet.debug = true

    Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(log_sink))
  end

  after(:each) do
    Puppet::Util::Log.close_all
  end

  it { expect { described_class.new(nil) }.to raise_error ArgumentError, %r{wrong number of arguments} }
  it { expect { described_class.new(name, type, definition, resource) }.not_to raise_error }

  describe '#value=(value)' do
    context 'when called from `puppet resource`' do
      context 'when the value set attempt is performed' do
        it 'value set fails' do
          expect { read_only_parameter.value=(value) }.to raise_error Puppet::ResourceError, %r{Attempting to set `some_parameter` read_only attribute value to `value`} # rubocop:disable Style/RedundantParentheses, Layout/SpaceAroundOperators
        end
      end
    end
  end

  describe '#value' do
    context 'when value is string' do
      context 'when the value is set' do
        before(:each) do
          allow(described_class).to receive(:value).and_return(result)
        end

        it('value is called') do
          described_class.value
          expect(described_class).to have_received(:value).once
        end

        it('value is returned') do
          expect(described_class.value).to eq result
        end
      end
    end
  end

  describe '#rs_value' do
    context 'when the value is not set' do
      it('nil is returned') do
        expect(read_only_parameter.value).to eq nil
      end
    end

    context 'when value is string' do
      context 'when the value is set' do
        it('value is called') do
          allow(described_class).to receive(:rs_value).and_return(result)
          described_class.rs_value
          expect(described_class).to have_received(:rs_value).once
        end

        it('value is returned') do
          read_only_parameter.instance_variable_set(:@value, value)
          expect(read_only_parameter.rs_value).to eq result
        end
      end
    end
  end
end
