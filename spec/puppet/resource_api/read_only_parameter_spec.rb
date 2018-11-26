require 'spec_helper'

RSpec.describe Puppet::ResourceApi::ReadOnlyParameter do
  subject(:read_only_parameter) do
    described_class.new(type_name, data_type, attribute_name, resource_hash)
  end

  let(:type_name) { 'test_name' }
  let(:attribute_name) { 'some_parameter' }
  let(:data_type) { Puppet::Pops::Types::PStringType }
  let(:resource_hash) { { resource: {} } }
  let(:result) { 'value' }
  let(:value) { 'value' }

  it { expect { described_class.new(nil) }.to raise_error ArgumentError, %r{wrong number of arguments} }
  it { expect { described_class.new(type_name, data_type, attribute_name, resource_hash) }.not_to raise_error }

  describe '#value=(value)' do
    context 'when called from `puppet resource`' do
      context 'when the value set attempt is performed' do
        it 'value set fails' do
          expect { read_only_parameter.value=(value) }.to raise_error( # rubocop:disable Style/RedundantParentheses, Layout/SpaceAroundOperators
            Puppet::ResourceError,
            %r{Attempting to set `some_parameter` read_only attribute value to `value`},
          )
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
