# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::ResourceApi::ValueCreator do
  subject(:value_creator) do
    described_class
  end

  let(:attribute_class) { Puppet::ResourceApi::Property }
  let(:data_type) { Puppet::Pops::Types::PEnumType.new(['absent', 'present']) } # rubocop:disable Style/WordArray
  let(:param_or_property) { :newproperty }
  let(:options) do
    {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present'
    }
  end

  before do
    allow(attribute_class).to receive(:newvalue)
    allow(attribute_class).to receive(:newvalues)
    allow(attribute_class).to receive(:aliasvalue)
    allow(attribute_class).to receive(:defaultto)
    allow(attribute_class).to receive(:isnamevar)
  end

  it { expect { described_class.create_values(nil) }.to raise_error ArgumentError, /wrong number of arguments/ }
  it { expect { value_creator }.not_to raise_error }

  describe '#create_values' do
    before do
      value_creator.create_values(attribute_class, data_type, param_or_property, options)
    end

    context 'when attribute class is property' do
      context 'when property is :ensure' do
        it 'calls #newvalue twice' do
          expect(Puppet::ResourceApi::Property).to have_received(:newvalue).with('absent')
          expect(Puppet::ResourceApi::Property).to have_received(:newvalue).with('present')
        end
      end

      context 'when default is set' do
        it 'calls #defaultto once' do
          expect(attribute_class).to have_received(:defaultto) { |&block| expect(block[0]).to eq('present') }
        end
      end

      context 'when property has Boolean type' do
        let(:data_type) { Puppet::Pops::Types::PBooleanType.new }
        let(:options) do
          {
            type: 'Boolean',
            desc: 'Boolean test.'
          }
        end

        it 'calls #newvalue twice' do
          expect(attribute_class).to have_received(:newvalue).with('true')
          expect(attribute_class).to have_received(:newvalue).with('false')
        end

        it 'calls #aliasvalue four times' do
          expect(attribute_class).to have_received(:aliasvalue).with(true, 'true')
          expect(attribute_class).to have_received(:aliasvalue).with(false, 'false')
          expect(attribute_class).to have_received(:aliasvalue).with(:true, 'true') # rubocop:disable Lint/BooleanSymbol
          expect(attribute_class).to have_received(:aliasvalue).with(:false, 'false') # rubocop:disable Lint/BooleanSymbol
        end
      end

      context 'when property has String type' do
        let(:data_type) { Puppet::Pops::Types::PStringType.new('s') }
        let(:options) do
          {
            type: 'String',
            desc: 'String test.'
          }
        end

        it 'calls #newvalue once' do
          expect(attribute_class).to have_received(:newvalue).with(//)
        end
      end

      context 'when property has Integer type' do
        let(:data_type) { Puppet::Pops::Types::PIntegerType.new(1) }
        let(:options) do
          {
            type: 'Integer',
            desc: 'Integer test.'
          }
        end

        it 'calls #newvalue once' do
          expect(attribute_class).to have_received(:newvalue).with(/^-?\d+$/)
        end
      end

      context 'when property has Float type' do
        let(:data_type) { Puppet::Pops::Types::PFloatType.new(1.0) }
        let(:options) do
          {
            type: 'Float',
            desc: 'Float test.'
          }
        end

        it 'calls #newvalue once' do
          expect(attribute_class).to have_received(:newvalue)
        end
      end
    end

    context 'when attribute class is parameter' do
      let(:attribute_class) { Puppet::ResourceApi::Parameter }
      let(:data_type) { Puppet::Pops::Types::PBooleanType.new }
      let(:param_or_property) { :newparam }

      it 'attribute_class has no #call_provider method' do
        expect(attribute_class.method_defined?(:call_provider)).to eq(false)
      end

      context 'when behaviour is set to :namevar' do
        let(:options) do
          {
            type: 'String',
            desc: 'Namevar test',
            behaviour: :namevar
          }
        end

        it 'calls #isnamevar once' do
          expect(attribute_class).to have_received(:isnamevar)
        end
      end

      context 'when default value is set' do
        let(:options) do
          {
            type: 'Boolean',
            desc: 'Default value test',
            default: true
          }
        end

        it 'calls #defaultto once' do
          expect(attribute_class).to have_received(:defaultto).with(:true) # rubocop:disable Lint/BooleanSymbol
        end
      end

      context 'when there is no default value' do
        let(:options) do
          {
            type: 'Boolean',
            desc: 'No default value test'
          }
        end

        it 'does not call #defaultto' do
          expect(attribute_class).not_to receive(:defaultto).with(nil)
        end
      end

      context 'when parameter has Boolean type' do
        let(:data_type) { Puppet::Pops::Types::PBooleanType.new }
        let(:options) do
          {
            type: 'Boolean',
            desc: 'Boolean test.'
          }
        end

        it 'calls #newvalues once' do
          expect(attribute_class).to have_received(:newvalues).with('true', 'false')
        end

        it 'calls #aliasvalue four times' do
          expect(attribute_class).to have_received(:aliasvalue).with(true, 'true')
          expect(attribute_class).to have_received(:aliasvalue).with(false, 'false')
          expect(attribute_class).to have_received(:aliasvalue).with(:true, 'true') # rubocop:disable Lint/BooleanSymbol
          expect(attribute_class).to have_received(:aliasvalue).with(:false, 'false') # rubocop:disable Lint/BooleanSymbol
        end
      end

      context 'when parameter has String type' do
        let(:data_type) { Puppet::Pops::Types::PStringType.new('s') }
        let(:options) do
          {
            type: 'String',
            desc: 'String test.'
          }
        end

        it 'calls #newvalues once' do
          expect(attribute_class).to have_received(:newvalues).with(//)
        end
      end

      context 'when parameter has Integer type' do
        let(:data_type) { Puppet::Pops::Types::PIntegerType.new(1) }
        let(:options) do
          {
            type: 'Integer',
            desc: 'Integer test.'
          }
        end

        it 'calls #newvalues once' do
          expect(attribute_class).to have_received(:newvalues).with(/^-?\d+$/)
        end
      end

      context 'when parameter has Float type' do
        let(:data_type) { Puppet::Pops::Types::PFloatType.new(1.0) }
        let(:options) do
          {
            type: 'Float',
            desc: 'Float test.'
          }
        end

        it 'calls #newvalues once' do
          expect(attribute_class).to have_received(:newvalues).with(
            /\A[[:blank:]]*([-+]?)[[:blank:]]*((0[xX][0-9A-Fa-f]+)|(0?\d+)((?:\.\d+)?(?:[eE]-?\d+)?))[[:blank:]]*\z/
          )
        end
      end
    end
  end
end
