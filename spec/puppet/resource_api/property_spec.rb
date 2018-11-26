require 'spec_helper'

RSpec.describe Puppet::ResourceApi::Property do
  subject(:property) do
    described_class.new(type_name, data_type, attribute_name, resource_hash)
  end

  let(:type_name) { 'test_name' }
  let(:attribute_name) { 'some_property' }
  let(:data_type) { Puppet::Pops::Types::PStringType.new(nil) }
  let(:resource_hash) { { resource: {} } }
  let(:result) { 'value' }

  it { expect { described_class.new(nil) }.to raise_error ArgumentError, %r{wrong number of arguments} }
  it { expect { described_class.new(type_name, data_type, attribute_name, resource_hash) }.not_to raise_error }

  describe '#should=(value)' do
    context 'when value is string' do
      context 'when the should is set with string value' do
        let(:value) { 'value' }

        it('value is called') do
          allow(described_class).to receive(:should=).with(value).and_return(result)
          allow(described_class).to receive(:rs_value).and_return(result)
          described_class.should=(value) # rubocop:disable Style/RedundantParentheses, Layout/SpaceAroundOperators
          expect(described_class).to have_received(:should=).once
        end

        it('value is returned') do
          expect(property.should=(value)).to eq result # rubocop:disable Style/RedundantParentheses, Layout/SpaceAroundOperators
        end
      end
    end
  end

  describe '#should' do
    context 'when value is boolean' do
      context 'when the @should is set' do
        let(:should_true_value) { [true] } # rs_value takes value in array
        let(:true_result) { :true } # rubocop:disable Lint/BooleanSymbol
        let(:should_false_value) { [false] } # rs_value takes value in array
        let(:false_result) { :false } # rubocop:disable Lint/BooleanSymbol

        it('true symbol value is returned') do
          property.instance_variable_set(:@should, should_true_value)
          expect(property.should).to eq true_result
        end

        it('false symbol value is returned') do
          property.instance_variable_set(:@should, should_false_value)
          expect(property.should).to eq false_result
        end
      end
    end

    context 'when value is string' do
      context 'when the name is :ensure' do
        context 'when the @should is set' do
          let(:should_value) { ['present'] } # rs_value takes value in array
          let(:name) { :ensure }
          let(:result) { 'present' }

          it('symbol value is returned') do
            property.instance_variable_set(:@should, should_value)
            property.instance_variable_set(:@name, name)
            expect(property.should).to eq result
          end
        end
      end

      context 'when the should is set' do
        let(:should_value) { ['value'] } # rs_value takes value in array

        it('value is called') do
          allow(described_class).to receive(:should).and_return(result)
          described_class.should
          expect(described_class).to have_received(:should).once
        end

        it('value is returned') do
          property.instance_variable_set(:@should, should_value)
          expect(property.should).to eq result
        end
      end
    end
  end

  describe '#rs_value' do
    context 'when the value is not set' do
      it('nil is returned') do
        expect(property.value).to eq nil
      end
    end

    context 'when value is string' do
      let(:should_value) { ['value'] }

      context 'when the value is set' do
        it('value is called') do
          allow(described_class).to receive(:rs_value).and_return(result)
          described_class.rs_value
          expect(described_class).to have_received(:rs_value).once
        end

        it('value is returned') do
          property.instance_variable_set(:@should, should_value)
          expect(property.rs_value).to eq result
        end
      end
    end
  end
end
