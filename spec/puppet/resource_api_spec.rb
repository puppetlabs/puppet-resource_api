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

    describe Puppet::Provider do
      it('has a module prepared for the provider') { expect(described_class.const_get('Minimal').name).to eq 'Puppet::Provider::Minimal' }
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
        it('the test_integer value is set correctly') { expect(instance[:test_integer]).to eq(-1) }
        it('the test_float value is set correctly') { expect(instance[:test_float]).to eq(-1.5) }
      end

      describe 'different boolean values' do
        let(:params) do
          {
            title: 'test',
            test_string: 'somevalue',
            test_boolean: the_boolean,
            test_integer: '-1',
            test_float: '-1.5',
          }
        end

        context 'when using :true' do
          let(:the_boolean) { :true }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq true }
        end
        context 'when using :false' do
          let(:the_boolean) { :false }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq false }
        end
        context 'when using "true"' do
          let(:the_boolean) { 'true' }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq true }
        end
        context 'when using "false"' do
          let(:the_boolean) { 'false' }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq false }
        end
        context 'when using true' do
          let(:the_boolean) { true }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq true }
        end
        context 'when using false' do
          let(:the_boolean) { false }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq false }
        end
      end
    end
  end

  context 'when registering a type with a malformed attributes' do
    let(:definition) do
      {
        name: 'no_type',
        attributes: {
          name: {
            behaviour: :namevar,
          },
        },
      }
    end

    it { expect { described_class.register_type(definition) }.to raise_error Puppet::DevError, %r{name.*has no type} }
  end

  describe '#load_provider' do
    before(:each) { described_class.register_type(definition) }

    context 'when loading a non-existing provider' do
      let(:definition) { { name: 'does_not_exist', attributes: {} } }

      it { expect { described_class.load_provider('does_not_exist') }.to raise_error Puppet::DevError, %r{puppet/provider/does_not_exist/does_not_exist} }
    end

    context 'when loading a provider that doesn\'t create the correct class' do
      let(:definition) { { name: 'no_class', attributes: {} } }

      it { expect { described_class.load_provider('no_class') }.to raise_error Puppet::DevError, %r{NoClass} }
    end

    context 'when loading a provider that doesn\'t create the correct class' do
      let(:definition) { { name: 'test_provider', attributes: {} } }

      it { expect(described_class.load_provider('test_provider').name).to eq 'Puppet::Provider::TestProvider::TestProvider' }
    end
  end

  context 'with a provider that does canonicalization' do
    let(:definition) do
      {
        name: 'canonicalizer',
        attributes: {
          name: {
            type: 'String',
            behaviour: :namevar,
          },
          test_string: {
            type: 'String',
          },
        },
        features: ['canonicalize'],
      }
    end
    let(:provider_class) do
      Class.new do
        def canonicalize(x)
          x[0][:test_string] = ['canon', x[0][:test_string]].compact.join unless x[0][:test_string] && x[0][:test_string].start_with?('canon')
          x
        end

        def get(_context)
          []
        end

        attr_reader :last_changes
        def set(_context, changes)
          @last_changes = changes
        end
      end
    end

    before(:each) do
      stub_const('Puppet::Provider::Canonicalizer', Module.new)
      stub_const('Puppet::Provider::Canonicalizer::Canonicalizer', provider_class)
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:canonicalizer) }

      before(:each) do
        allow(type.my_provider).to receive(:get)
          .with(kind_of(Puppet::ResourceApi::BaseContext))
          .and_return([{ name: 'somename', test_string: 'canonfoo' },
                       { name: 'other', test_string: 'canonbar' }])
      end

      it { is_expected.not_to be_nil }

      context 'when manually creating an instance' do
        let(:test_string) { 'foo' }
        let(:instance) { type.new(name: 'somename', test_string: test_string) }

        it('its provider class') { expect(instance.my_provider).not_to be_nil }
        it('its test_string value is canonicalized') { expect(instance[:test_string]).to eq('canonfoo') }

        context 'when flushing' do
          before(:each) do
            instance.flush
          end
          context 'with no changes' do
            it('set will not be called') { expect(instance.my_provider.last_changes).to be_nil }
          end

          context 'with a change' do
            let(:test_string) { 'bar' }

            it('set will be called with the correct structure') do
              expect(instance.my_provider.last_changes).to eq('somename' => {
                                                                is: { name: 'somename', test_string: 'canonfoo' },
                                                                should: { name: 'somename', test_string: 'canonbar' },
                                                              })
            end
          end
        end
      end

      context 'when retrieving instances through `get`' do
        it('instances returns an Array') { expect(type.instances).to be_a Array }
        it('returns an array of TypeShims') { expect(type.instances[0]).to be_a Puppet::SimpleResource::TypeShim }
        it('its name is set correctly') { expect(type.instances[0].name).to eq 'somename' }
      end

      context 'when retrieving an instance through `retrieve`' do
        let(:resource) { instance.retrieve }

        describe 'an existing instance' do
          let(:instance) { type.new(name: 'somename') }

          it('its name is set correctly') { expect(resource[:name]).to eq 'somename' }
          it('its properties are set correctly') { expect(resource[:test_string]).to eq 'canonfoo' }
        end

        describe 'an absent instance' do
          let(:instance) { type.new(name: 'does_not_exist') }

          it('its name is set correctly') { expect(resource[:name]).to eq 'does_not_exist' }
          it('its properties are set correctly') { expect(resource[:test_string]).to be_nil }
          it('is set to absent') { expect(resource[:ensure]).to eq :absent }
        end
      end
    end
  end
end
