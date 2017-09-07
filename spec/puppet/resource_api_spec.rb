require 'spec_helper'

RSpec.describe Puppet::ResourceApi do
  it 'has a version number' do
    expect(Puppet::ResourceApi::VERSION).not_to be nil
  end

  context 'when registering a definition with missing keys' do
    it { expect { described_class.register_type([]) }.to raise_error(Puppet::DevError, %r{requires a Hash as definition}) }
    it { expect { described_class.register_type({}) }.to raise_error(Puppet::DevError, %r{requires a name}) }
    it { expect { described_class.register_type(name: 'no attributes') }.to raise_error(Puppet::DevError, %r{requires attributes}) }
  end

  context 'when registering a minimal type' do
    let(:definition) { { name: 'minimal', attributes: {} } }

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:minimal) }

      it { is_expected.not_to be_nil }
      it { is_expected.to be_respond_to :instances }
    end
  end

  context 'when registering a type with multiple attributes' do
    let(:definition) do
      {
        name: 'with_string',
        attributes: {
          name: {
            type: 'String',
            behaviour: :namevar,
            desc: 'the title',
          },
          test_string: {
            type: 'String',
            desc: 'the description',
            default: 'default value',
          },
          test_boolean: {
            type: 'Boolean',
            desc: 'a boolean value',
          },
          test_integer: {
            type: 'Integer',
            desc: 'an integer value',
          },
          test_float: {
            type: 'Float',
            desc: 'a floating point value',
          },
        },
      }
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:with_string) }

      it { is_expected.not_to be_nil }
      it { expect(type.properties.first.doc).to match %r{the description} }
      it { expect(type.properties.first.name).to eq :test_string }
    end

    describe 'an instance of this type' do
      subject(:instance) { Puppet::Type.type(:with_string).new(params) }

      let(:params) { { title: 'test' } }

      it('uses defaults correctly') { expect(instance[:test_string]).to eq 'default value' }

      context 'when setting a value for the attributes' do
        let(:params) do
          {
            title: 'test',
            test_string: 'somevalue',
            test_boolean: 'true',
            test_integer: '-1',
            test_float: '-1.5',
          }
        end

        it('the test_string value is set correctly') { expect(instance[:test_string]).to eq 'somevalue' }
        it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq true }
        it('the test_integer value is set correctly') { expect(instance[:test_integer]).to eq(-1) }
        it('the test_float value is set correctly') { expect(instance[:test_float]).to eq(-1.5) }
      end
    end
  end
end
