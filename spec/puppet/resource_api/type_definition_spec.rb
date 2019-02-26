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
