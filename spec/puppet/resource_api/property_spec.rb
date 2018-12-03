require 'spec_helper'

RSpec.describe Puppet::ResourceApi::Property do
  subject(:property) do
    described_class.new(type_name, data_type, attribute_name, resource_hash)
  end

  let(:type_name) { 'test_name' }
  let(:attribute_name) { 'some_property' }
  let(:data_type) { Puppet::Pops::Types::PStringType.new(nil) }
  let(:resource_hash) { { resource: {} } }

  describe '#new(type_name, data_type, attribute_name, resource_hash)' do
    it { expect { described_class.new(nil) }.to raise_error ArgumentError, %r{wrong number of arguments} }
    it { expect { described_class.new(type_name, data_type, attribute_name, resource_hash) }.not_to raise_error }
  end

  describe 'should error handling' do
    it 'calls mungify and reports its error' do
      expect(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .and_raise Exception, 'error'

      expect { property.should = 'value' }.to raise_error Exception, 'error'

      expect(property.should).to eq nil
    end
  end

  describe 'value munging and storage' do
    before(:each) do
      allow(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .with(data_type, value, 'test_name.some_property', false)
        .and_return(munged_value)

      property.should = value
    end

    context 'when handling strings' do
      let(:value) { 'value' }
      let(:munged_value) { 'munged value' }

      it { expect(property.should).to eq 'munged value' }
      it { expect(property.rs_value).to eq 'munged value' }
      it { expect(property.value).to eq 'munged value' }
    end

    context 'when handling boolean true' do
      let(:value) { true }
      let(:munged_value) { true }
      let(:data_type) { Puppet::Pops::Types::PBooleanType.new }

      it { expect(property.should).to eq :true } # rubocop:disable Lint/BooleanSymbol
      it { expect(property.rs_value).to eq true }
      it { expect(property.value).to eq :true } # rubocop:disable Lint/BooleanSymbol
    end
  end
end
