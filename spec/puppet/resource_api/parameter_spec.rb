require 'spec_helper'

RSpec.describe Puppet::ResourceApi::Parameter do
  subject(:parameter) do
    described_class.new(type_name, data_type, attribute_name, resource_hash)
  end

  let(:type_name) { 'test_name' }
  let(:attribute_name) { 'some_parameter' }
  let(:data_type) { Puppet::Pops::Types::PStringType.new(nil) }
  let(:resource_hash) { { resource: {} } }

  describe '#new(type_name, data_type, attribute_name, resource_hash)' do
    it { expect { described_class.new(nil) }.to raise_error ArgumentError, %r{wrong number of arguments} }
    it { expect { described_class.new(type_name, data_type, attribute_name, resource_hash) }.not_to raise_error }
  end

  describe '#value=(value)' do
    it 'calls mungify and stores the munged value' do
      expect(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .with(data_type, 'value', 'test_name.some_parameter', false)
        .and_return('munged value')

      parameter.value = 'value'

      expect(parameter.value).to eq 'munged value'
    end

    it 'calls mungify and reports its error' do
      expect(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .and_raise Exception, 'error'

      expect { parameter.value = 'value' }.to raise_error Exception, 'error'

      expect(parameter.value).to eq nil
    end
  end

  describe '#value' do
    context 'when the value is not set' do
      it 'nil is returned' do
        expect(parameter.value).to eq nil
      end
    end

    context 'when the value is set' do
      it 'value is returned' do
        parameter.instance_variable_set(:@value, 'value')
        expect(parameter.value).to eq 'value'
      end
    end
  end

  describe '#rs_value' do
    context 'when the value is not set' do
      it 'nil is returned' do
        expect(parameter.rs_value).to eq nil
      end
    end

    context 'when the value is set' do
      it 'value is returned' do
        parameter.instance_variable_set(:@value, 'value')
        expect(parameter.rs_value).to eq 'value'
      end
    end
  end
end
