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

  describe 'value error handling' do
    it 'calls mungify and reports its error' do
      expect(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .and_raise Exception, 'error'

      expect { parameter.value = 'value' }.to raise_error Exception, 'error'

      expect(parameter.value).to eq nil
    end
  end

  describe 'value munging and storage' do
    before(:each) do
      allow(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .with(data_type, value, 'test_name.some_parameter', false)
        .and_return(munged_value)

      parameter.value = value
    end

    context 'when handling strings' do
      let(:value) { 'value' }
      let(:munged_value) { 'munged value' }

      it { expect(parameter.rs_value).to eq 'munged value' }
      it { expect(parameter.value).to eq 'munged value' }
    end

    context 'when handling boolean true' do
      let(:value) { true }
      let(:munged_value) { true }
      let(:data_type) { Puppet::Pops::Types::PBooleanType.new }

      it { expect(parameter.rs_value).to eq true }
      it { expect(parameter.value).to eq true }
    end
  end
end
