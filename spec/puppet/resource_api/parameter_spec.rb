require 'spec_helper'

RSpec.describe Puppet::ResourceApi::Parameter do
  subject(:parameter) do
    described_class.new(type_name, data_type, attribute_name, resource_hash)
  end

  let(:type_name) { 'test_name' }
  let(:attribute_name) { 'some_parameter' }
  let(:data_type) { Puppet::Pops::Types::PStringType.new(nil) }
  let(:resource_hash) { { resource: {} } }
  let(:result) { 'value' }
  let(:value) { 'value' }

  it { expect { described_class.new(nil) }.to raise_error ArgumentError, %r{wrong number of arguments} }
  it { expect { described_class.new(type_name, data_type, attribute_name, resource_hash) }.not_to raise_error }

  describe '#value=(value)' do
    context 'when value is string' do
      context 'when the value is set with string value' do
        it('value is returned') do
          expect(parameter.value=(value)).to eq result # rubocop:disable Style/RedundantParentheses, Layout/SpaceAroundOperators
        end

        it('value=(value) is called') do
          allow(described_class).to receive(:value=).with(value).and_return(result)
          described_class.value=(value) # rubocop:disable Style/RedundantParentheses, Layout/SpaceAroundOperators
          expect(described_class).to have_received(:value=).once
        end
      end
    end
  end

  describe '#value' do
    context 'when the value is not set' do
      it('nil is returned') do
        expect(parameter.value).to eq nil
      end
    end

    context 'when value is string' do
      context 'when the value is set' do
        it('value is called') do
          allow(described_class).to receive(:value).and_return(result)
          described_class.value
          expect(described_class).to have_received(:value).once
        end

        it('value is returned') do
          parameter.instance_variable_set(:@value, value)
          expect(parameter.value).to eq result
        end
      end
    end
  end

  describe '#rs_value' do
    context 'when the value is not set' do
      it('nil is returned') do
        expect(parameter.value).to eq nil
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
          parameter.instance_variable_set(:@value, value)
          expect(parameter.rs_value).to eq result
        end
      end
    end
  end
end
