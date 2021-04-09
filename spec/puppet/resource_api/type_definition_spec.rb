require 'spec_helper'

RSpec.describe Puppet::ResourceApi::TypeDefinition do
  subject(:type) { described_class.new(definition) }

  let(:definition) do
    { name: 'some_resource', attributes: {
      ensure:      {
        type:    'Enum[present, absent]',
        desc:    'Whether this resource should be present or absent on the target system.',
        default: 'present',
      },
      name:        {
        type:      'String',
        desc:      'The name of the resource you want to manage.',
        behaviour: :namevar,
      },
      prop:        {
        type:      'Integer',
        desc:      'A mandatory property, that MUST NOT be validated on deleting.',
      },
    }, features: feature_support }
  end
  let(:feature_support) { [] }

  it { expect { described_class.new(nil) }.to raise_error Puppet::DevError, %r{TypeDefinition must be a Hash} }

  describe '#ensurable?' do
    context 'when type is ensurable' do
      let(:definition) { { name: 'ensurable', attributes: { ensure: { type: 'Enum[absent, present]' } } } }

      it { expect(type).to be_ensurable }
      it { expect(type.attributes).to be_key(:ensure) }
    end

    context 'when type is not ensurable' do
      let(:definition) { { name: 'ensurable', attributes: { name: { type: 'String' } } } }

      it { expect(type).not_to be_ensurable }
      it { expect(type.attributes).to be_key(:name) }
    end
  end

  describe '#has_feature?' do
    context 'when type supports feature' do
      let(:feature_support) { ['simple_get_filter'] }

      it { expect(type).to be_feature('simple_get_filter') }
    end

    context 'when type does not support a feature' do
      let(:feature_support) { ['cannonicalize'] }

      it { expect(type).not_to be_feature('simple_get_filter') }
    end
  end

  describe '#create_attribute_in' do
    let(:puppet_type) { instance_double('Puppet::Type', 'example_type') }
    let(:foo_options) do
      {
        type: 'String',
        desc: 'Example description for foo',
        default: 'bar',
      }
    end
    let(:definition) { { name: 'example_type', attributes: { foo: foo_options } } }

    context 'when creating a valid attribute' do
      it 'creates a Puppet::Property object' do
        expect(puppet_type).to receive(:send).with(:newproperty, :foo, parent: Puppet::ResourceApi::Property)
        type.create_attribute_in(puppet_type, :foo, :newproperty, Puppet::ResourceApi::Property, foo_options)
      end
    end

    context 'when creating an invalid attribute' do
      it 'errors cleanly'
    end
  end

  describe '#insyncable_attributes' do
    context 'when the definition includes an insyncable attribute' do
      let(:definition) { { name: 'insyncer', attributes: { name: { type: 'String' } } } }

      it { expect(type.insyncable_attributes).to eq([:name]) }
    end

    context 'when the definition does not include an insyncable attribute' do
      let(:definition) do
        {
          name: 'insyncer',
          attributes: {
            name: { type: 'String', behaviour: :namevar },
            only_readable: { type: 'String', behaviour: :read_only },
            only_settable: { type: 'String', behaviour: :parameter },
            only_initable: { type: 'String', behaviour: :init_only },
          },
        }
      end

      it { expect(type.insyncable_attributes).to eq([]) }
    end
  end

  describe '#initialize' do
    context 'when the custom_insync feature is specified' do
      context 'when the definition includes an insyncable attribute' do
        let(:definition) { { name: 'insyncer', features: ['custom_insync'], attributes: { name: { type: 'String' } } } }

        it { expect(type.attributes).to be_key(:name) }
        it { expect(type.attributes).not_to be_key(:rsapi_custom_insync_trigger) }
      end

      context 'when the definition does not include an insyncable attribute' do
        let(:definition) { { name: 'insyncer', features: ['custom_insync'], attributes: { name: { type: 'String', behaviour: :parameter } } } }

        it { expect(type.attributes).to be_key(:name) }
        it { expect(type.attributes).not_to be_key(:rsapi_custom_insync_trigger) }
      end
    end

    context 'when the custom_insync feature is not specified' do
      context 'when the definition includes an insyncable attribute' do
        let(:definition) { { name: 'insyncer', attributes: { name: { type: 'String' } } } }

        it { expect(type.attributes).to be_key(:name) }
        it { expect(type.attributes).not_to be_key(:rsapi_custom_insync_trigger) }
      end

      context 'when the definition does not include an insyncable attribute' do
        let(:definition) { { name: 'insyncer', attributes: { name: { type: 'String', behaviour: :parameter } } } }

        it { expect(type.attributes).to be_key(:name) }
        it { expect(type.attributes).not_to be_key(:rsapi_custom_insync_trigger) }
      end
    end
  end

  describe '#attributes' do
    context 'when type has attributes' do
      it { expect(type.attributes).to be_key(:ensure) }
      it { expect(type.attributes).to be_key(:name) }
      it { expect(type.attributes).to be_key(:prop) }
    end
  end

  describe '#validate_schema' do
    context 'when the schema contains title_patterns and it is not an array' do
      let(:definition) { { name: 'some_resource', title_patterns: {}, attributes: {} } }

      it { expect { type }.to raise_error Puppet::DevError, %r{`:title_patterns` must be an array} }
    end
  end
end
