require 'spec_helper'

RSpec.describe Puppet::ResourceApi::ValueCreator do
  subject(:value_creator) do
    described_class
  end

  let(:resource_class) { Puppet::ResourceApi::Property }
  let(:data_type) { Puppet::Pops::Types::PEnumType.new(['absent', 'present']) } # rubocop:disable Style/WordArray
  let(:param_or_property) { :newproperty }
  let(:options) do
    {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present',
    }
  end

  before(:each) do
    allow(resource_class).to receive(:newvalue)
    allow(resource_class).to receive(:newvalues)
    allow(resource_class).to receive(:aliasvalue)
    allow(resource_class).to receive(:defaultto)
    allow(resource_class).to receive(:isnamevar)
  end

  it { expect { described_class.create_values(nil) }.to raise_error ArgumentError, %r{wrong number of arguments} }
  it { expect { value_creator }.not_to raise_error }

  describe '#create_values' do
    before(:each) do
      value_creator.create_values(resource_class, data_type, param_or_property, options)
    end

    context 'when resource class is property' do
      it 'resource_class has #call_provider defined' do
        expect(resource_class.method_defined?(:call_provider)).to eq(true)
      end

      context 'when property is :ensure' do
        it 'calls #newvalue twice' do
          expect(Puppet::ResourceApi::Property).to have_received(:newvalue).twice
        end
      end

      context 'when default is set' do
        it 'calls #defaultto once' do
          expect(resource_class).to have_received(:defaultto)
        end
      end

      context 'when property has Boolean type' do
        let(:data_type) { Puppet::Pops::Types::PBooleanType.new }
        let(:options) do
          {
            type: 'Boolean',
            desc: 'Boolean test.',
          }
        end

        it 'calls #newvalue twice' do
          expect(resource_class).to have_received(:newvalue).twice
        end

        it 'calls #aliasvalue four times' do
          expect(resource_class).to have_received(:aliasvalue).at_least(4).times
        end
      end

      context 'when property has String type' do
        let(:data_type) { Puppet::Pops::Types::PStringType.new('s') }
        let(:options) do
          {
            type: 'String',
            desc: 'String test.',
          }
        end

        it 'calls #newvalue twice' do
          expect(resource_class).to have_received(:newvalue).once
        end
      end

      context 'when property has Integer type' do
        let(:data_type) { Puppet::Pops::Types::PIntegerType.new(1) }
        let(:options) do
          {
            type: 'Integer',
            desc: 'Integer test.',
          }
        end

        it 'calls #newvalue twice' do
          expect(resource_class).to have_received(:newvalue).once
        end
      end

      context 'when property has Float type' do
        let(:data_type) { Puppet::Pops::Types::PFloatType.new(1.0) }
        let(:options) do
          {
            type: 'Float',
            desc: 'Float test.',
          }
        end

        it 'calls #newvalue twice' do
          expect(resource_class).to have_received(:newvalue).once
        end
      end
    end

    context 'when resource class is parameter' do
      let(:resource_class) { Puppet::ResourceApi::Parameter }
      let(:data_type) { Puppet::Pops::Types::PBooleanType.new }
      let(:param_or_property) { :newparam }

      it 'resource_class has no #call_provider method' do
        expect(resource_class.method_defined?(:call_provider)).to eq(false)
      end

      context 'when behaviour is set to :namevar' do
        let(:options) do
          {
            type: 'String',
            desc: 'Namevar test',
            behaviour: :namevar,
          }
        end

        it 'calls #isnamevar once' do
          expect(resource_class).to have_received(:isnamevar).once
        end
      end

      context 'when default value is set' do
        let(:options) do
          {
            type: 'Boolean',
            desc: 'Default value test',
            default: true,
          }
        end

        it 'calls #defaultto once' do
          expect(resource_class).to have_received(:defaultto).once
        end
      end

      context 'when there is no default value' do
        let(:options) do
          {
            type: 'Boolean',
            desc: 'No default value test',
          }
        end

        it 'does not call #defaultto' do
          expect(resource_class).not_to receive(:defaultto)
        end
      end

      context 'when parameter has Boolean type' do
        let(:data_type) { Puppet::Pops::Types::PBooleanType.new }
        let(:options) do
          {
            type: 'Boolean',
            desc: 'Boolean test.',
          }
        end

        it 'calls #newvalues twice' do
          expect(resource_class).to have_received(:newvalues).once
        end

        it 'calls #aliasvalue four times' do
          expect(resource_class).to have_received(:aliasvalue).at_least(4).times
        end
      end

      context 'when parameter has String type' do
        let(:data_type) { Puppet::Pops::Types::PStringType.new('s') }
        let(:options) do
          {
            type: 'String',
            desc: 'String test.',
          }
        end

        it 'calls #newvalues twice' do
          expect(resource_class).to have_received(:newvalues).once
        end
      end

      context 'when parameter has Integer type' do
        let(:data_type) { Puppet::Pops::Types::PIntegerType.new(1) }
        let(:options) do
          {
            type: 'Integer',
            desc: 'Integer test.',
          }
        end

        it 'calls #newvalues twice' do
          expect(resource_class).to have_received(:newvalues).once
        end
      end

      context 'when parameter has Float type' do
        let(:data_type) { Puppet::Pops::Types::PFloatType.new(1.0) }
        let(:options) do
          {
            type: 'Float',
            desc: 'Float test.',
          }
        end

        it 'calls #newvalues twice' do
          expect(resource_class).to have_received(:newvalues).once
        end
      end
    end
  end
end
