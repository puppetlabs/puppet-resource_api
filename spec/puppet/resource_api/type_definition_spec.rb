require 'spec_helper'

RSpec.describe Puppet::ResourceApi::TypeDefinition do
  subject(:type) { described_class.new(definition) }

  let(:definition) { { name: 'some_resource', attributes: { name: 'some_resource' }, features: feature_support } }
  let(:feature_support) { [] }

  it { expect { described_class.new(nil) }.to raise_error Puppet::DevError, %r{TypeDefinition requires definition to be a Hash} }

  describe '#ensurable?' do
    context 'when type is ensurable' do
      let(:definition) { { attributes: { ensure: true } } }

      it { expect(type).to be_ensurable }
      it { expect(type.attributes).to be_key(:ensure) }
    end
    context 'when type is not ensurable' do
      let(:definition) { { attributes: { string: 'something' } } }

      it { expect(type).not_to be_ensurable }
      it { expect(type.attributes).to be_key(:string) }
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
      let(:definition) { { attributes: { string: 'test_string' } } }

      it { expect(type.attributes).to be_key(:string) }
      it { expect(type.attributes[:string]).to eq('test_string') }
    end
  end
end
