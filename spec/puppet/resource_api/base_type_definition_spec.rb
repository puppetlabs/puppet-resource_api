require 'spec_helper'

RSpec.describe Puppet::ResourceApi::BaseTypeDefinition do
  subject(:type) { described_class.new(definition, :attributes) }

  let(:definition) do
    { name: 'some_resource',
      desc: 'some desc',
      attributes: {
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

  it { expect { described_class.new(nil, :attributes) }.to raise_error Puppet::DevError, %r{BaseTypeDefinition must be a Hash} }

  describe '.name' do
    it { expect(type.name).to eq 'some_resource' }
  end

  describe '#check_schema_keys' do
    context 'when resource contains only valid keys' do
      it 'returns an empty array' do
        expect(type.check_schema_keys(definition[:attributes])).to eq([])
      end
    end

    context 'when resource contains invalid keys' do
      let(:resource) { { name: 'test_string', wibble: '1', foo: '2' } }
      let(:resource_copy) { { name: 'test_string', wibble: '1', foo: '2' } }

      it 'returns an array containing the bad keys' do
        expect(type.check_schema_keys(resource)).to eq([:wibble, :foo])
      end

      it 'does not modify the resource passed in' do
        type.check_schema_keys(resource)
        expect(resource).to eq(resource_copy)
      end
    end
  end

  describe '#check_schema_values' do
    context 'when the definition is a type' do
      context 'when resource contains only valid values' do
        let(:resource) { { name: 'some_resource', prop: 1, ensure: 'present' } }

        it 'returns an empty array' do
          expect(type.check_schema_values(resource)).to eq({})
        end
      end

      context 'when resource contains invalid values' do
        let(:resource) { { name: 'test_string', prop: 'foo', ensure: 1 } }

        it 'returns a hash of the keys that have invalid values' do
          expect(type.check_schema_values(resource)).to eq(prop: 'foo', ensure: 1)
        end
      end
    end

    context 'when the definition is a transport' do
      subject(:type) { described_class.new(definition, :connection_info) }

      let(:definition) do
        {
          name: 'some_transport',
          desc: 'some desc',
          connection_info: {
            username:        {
              type:      'String',
              desc:      'The username to connect with',
            },
            secret:        {
              type:      'String',
              desc:      'A sensitive value',
              sensitive: true,
            },
          },
        }
      end

      context 'when resource contains only valid values' do
        let(:resource) { { username: 'wibble', secret: 'foo' } }

        it 'returns an empty array' do
          expect(type.check_schema_values(resource)).to eq({})
        end
      end

      context 'when resource contains invalid values' do
        let(:resource) { { username: 'wibble', secret: 12_345 } }

        it 'returns a hash of the keys that have invalid values' do
          expect(type.check_schema_values(resource)).to match(secret: %r{<< redacted value >> expect(s|ed) a String value, got Integer})
        end
      end
    end
  end

  describe '#check_schema' do
    context 'when resource does not contain its namevar' do
      let(:resource) { { nom: 'some_resource', prop: 1, ensure: 'present' } }

      it { expect { type.check_schema(resource) }.to raise_error Puppet::ResourceError, %r{`some_resource.get` did not return a value for the `name` namevar attribute} }
    end

    context 'when a resource contains unknown attributes' do
      let(:resource) { { name: 'wibble', prop: 1, ensure: 'present', foo: 'bar' } }
      let(:message) { %r{Provider returned data that does not match the Type Schema for `some_resource\[wibble\]`\n\s*Unknown attribute:\n\s*\* foo} }
      let(:strict_level) { :warning }

      before(:each) do
        Puppet::ResourceApi.warning_count = 0
        Puppet.settings[:strict] = strict_level
      end

      context 'when puppet strict is set to default (warning)' do
        it 'displays up to 100 warnings' do
          expect(Puppet).to receive(:warning).with(message).exactly(100).times
          110.times do
            type.check_schema(resource)
          end
        end
      end

      context 'when puppet strict is set to error' do
        let(:strict_level) { :error }

        it 'raises a DevError' do
          expect { type.check_schema(resource) }.to raise_error Puppet::DevError, message
        end
      end

      context 'when puppet strict is set to off' do
        let(:strict_level) { :off }

        it 'logs to Debug console' do
          expect(Puppet).to receive(:debug).with(message)
          type.check_schema(resource)
        end
      end
    end

    context 'when a resource contains invalid value' do
      let(:resource) { { name: 'wibble', prop: 'foo', ensure: 'present' } }
      let(:message) { %r{Provider returned data that does not match the Type Schema for `some_resource\[wibble\]`\n\s*Value type mismatch:\n\s*\* prop: foo} }
      let(:strict_level) { :warning }

      before(:each) do
        Puppet::ResourceApi.warning_count = 0
        Puppet.settings[:strict] = strict_level
      end

      context 'when puppet strict is set to default (warning)' do
        it 'displays up to 100 warnings' do
          expect(Puppet).to receive(:warning).with(message).exactly(100).times
          110.times do
            type.check_schema(resource)
          end
        end
      end

      context 'when puppet strict is set to error' do
        let(:strict_level) { :error }

        it 'raises a DevError' do
          expect { type.check_schema(resource) }.to raise_error Puppet::DevError, message
        end
      end

      context 'when puppet strict is set to off' do
        let(:strict_level) { :off }

        it 'logs to Debug console' do
          expect(Puppet).to receive(:debug).with(message)
          type.check_schema(resource)
        end
      end
    end
  end

  describe '#validate_schema' do
    context 'when the type definition does not have a name' do
      let(:definition) { { attributes: 'some_string' } }

      it { expect { type }.to raise_error Puppet::DevError, %r{must have a name} }
    end

    context 'when attributes is not a hash' do
      let(:definition) { { name: 'some_resource', attributes: 'some_string' } }

      it { expect { type }.to raise_error Puppet::DevError, %r{`some_resource.attributes` must be a hash} }
    end

    context 'when an attribute is not a hash' do
      let(:definition) { { name: 'some_resource', attributes: { name: 'some_string' } } }

      it { expect { type }.to raise_error Puppet::DevError, %r{`some_resource.name` must be a Hash} }
    end

    context 'when an attribute has no type' do
      let(:definition) { { name: 'some_resource', attributes: { name: { desc: 'message' } } } }

      it { expect { type }.to raise_error Puppet::DevError, %r{has no type} }
    end

    context 'when an attribute has no descrption' do
      let(:definition) { { name: 'some_resource', desc: 'some desc', attributes: { name: { type: 'String' } } } }

      it 'Raises a warning message' do
        expect(Puppet).to receive(:warning).with('`some_resource.name` has no documentation, add it using a `desc` key')
        type
      end
    end

    context 'when an attribute has an unsupported type' do
      let(:definition) { { name: 'some_resource', attributes: { name: { type: 'basic' } } } }

      it { expect { type }.to raise_error %r{<basic> is not a valid type specification} }
    end

    context 'with both behavior and behaviour' do
      let(:definition) do
        {
          name: 'bad_behaviour',
          attributes: {
            name: {
              type: 'String',
              behaviour: :namevar,
              behavior: :namevar,
            },
          },
        }
      end

      it { expect { type }.to raise_error Puppet::DevError, %r{name.*attribute has both} }
    end

    context 'when registering a type with badly formed attribute type' do
      let(:definition) do
        {
          name: 'bad_syntax',
          attributes: {
            name: {
              type: 'Optional[String',
            },
          },
        }
      end

      it { expect { type }.to raise_error Puppet::DevError, %r{The type of the `name` attribute `Optional\[String` could not be parsed:} }
    end
  end
end
