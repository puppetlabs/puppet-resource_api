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

    context 'when name is :ensure' do
      let(:attribute_name) { :ensure }

      it 'the #insync? method is avaliable' do
        expect(property.methods.include?(:insync?)).to eq true
      end
    end
  end

  describe '#should=(value)' do
    context 'when value is string type' do
      it 'calls mungify and stores the munged value' do
        expect(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
          .with(data_type, 'value', 'test_name.some_property', false)
          .and_return('munged value')

        property.should = 'value'

        expect(property.value).to eq 'munged value'
      end
    end

    context 'when attribute name is :ensure' do
      let(:attribute_name) { :ensure }
      let(:data_type) { Puppet::Pops::Types::PEnumType.new(%w[absent present]) }

      it 'calls mungify and stores the munged symbol value' do
        expect(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
          .with(data_type, 'absent', 'test_name.ensure', false)
          .and_return('absent')

        property.should = :absent

        expect(property.should).to eq :absent
      end
    end

    it 'calls mungify and stores the munged value' do
      expect(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .with(data_type, 'value', 'test_name.some_property', false)
        .and_return('munged value')

      property.should = 'value'

      expect(property.value).to eq 'munged value'
    end

    it 'calls mungify and reports its error' do
      expect(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .and_raise Exception, 'error'

      expect { property.should = 'value' }.to raise_error Exception, 'error'

      expect(property.should).to eq nil
    end
  end

  describe '#should' do
    context 'when the should is not set' do
      it 'nil is returned' do
        expect(property.should).to eq nil
      end
    end

    context 'when the should is set' do
      context 'when should is string' do
        it 'value is returned' do
          property.instance_variable_set(:@should, ['value'])
          expect(property.should).to eq 'value'
        end
      end

      context 'when should is boolean' do
        it ':false symbol value is returned' do
          property.instance_variable_set(:@should, [false])
          expect(property.should).to eq :false # rubocop:disable Lint/BooleanSymbol
        end

        it ':true symbol value is returned' do
          property.instance_variable_set(:@should, [true])
          expect(property.should).to eq :true # rubocop:disable Lint/BooleanSymbol
        end
      end

      context 'when atribute name is :ensure' do
        let(:attribute_name) { :ensure }

        it 'symbol value is returned' do
          property.instance_variable_set(:@should, ['present'])
          expect(property.should).to eq :present
        end
      end
    end
  end

  describe '#rs_value' do
    context 'when the value is not set' do
      it 'nil is returned' do
        expect(property.rs_value).to eq nil
      end
    end

    context 'when the value is set' do
      it 'value is returned' do
        property.instance_variable_set(:@should, ['value'])
        expect(property.rs_value).to eq 'value'
      end
    end
  end
end
