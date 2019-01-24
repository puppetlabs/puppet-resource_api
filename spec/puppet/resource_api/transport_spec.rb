require 'spec_helper'

RSpec.describe Puppet::ResourceApi::Transport do
  let(:strict_level) { :error }

  before(:each) do
    # set default to strictest setting
    # by default Puppet runs at warning level
    Puppet.settings[:strict] = strict_level
    # Enable debug logging
    Puppet.debug = true
  end

  after(:each) do
    # reset registered transports between tests to reduce cross-test poisoning
    described_class.instance_variable_set(:@transports, nil)
  end

  describe '#register(schema)' do
    context 'when registering a schema with missing keys' do
      it { expect { described_class.register([]) }.to raise_error(Puppet::DevError, %r{requires a hash as schema}) }
      it { expect { described_class.register({}) }.to raise_error(Puppet::DevError, %r{requires a `:name`}) }
      it { expect { described_class.register(name: 'no connection info', desc: 'some description') }.to raise_error(Puppet::DevError, %r{requires `:connection_info`}) }
      it { expect { described_class.register(name: 'no description') }.to raise_error(Puppet::DevError, %r{requires `:desc`}) }
      it { expect { described_class.register(name: 'no hash attributes', desc: 'some description', connection_info: []) }.to raise_error(Puppet::DevError, %r{`:connection_info` must be a hash, not}) }
    end

    context 'when registering a minimal transport' do
      let(:schema) { { name: 'minimal', desc: 'a  minimal connection', connection_info: {} } }

      it { expect { described_class.register(schema) }.not_to raise_error }

      context 'when re-registering a transport' do
        it {
          described_class.register(schema)
          expect { described_class.register(schema) }.to raise_error(Puppet::DevError, %r{`minimal` is already registered})
        }
      end
    end

    context 'when registering a transport' do
      let(:schema) do
        {
          name: 'a_remote_thing',
          desc: 'basic transport',
          connection_info: {
            host: {
              type: 'String',
              desc: 'the host ip address or hostname',
            },
            user: {
              type: 'String',
              desc: 'the user to connect as',
            },
            password: {
              type: 'String',
              sensitive: true,
              desc: 'the password to make the connection',
            },
          },
        }
      end

      it 'adds to the transports register' do
        expect { described_class.register(schema) }.not_to raise_error
      end
    end

    context 'when registering a transport with a bad type' do
      let(:schema) do
        {
          name: 'a_bad_thing',
          desc: 'basic transport',
          connection_info: {
            host: {
              type: 'garbage',
              desc: 'the host ip address or hostname',
            },
          },
        }
      end

      it {
        expect { described_class.register(schema) }.to raise_error(
          Puppet::DevError, %r{<garbage> is not a valid type specification}
        )
      }
    end
  end

  describe '#list' do
    subject { described_class.list }

    context 'with no transports registered' do
      it { is_expected.to eq({}) }
    end

    context 'with a transport registered' do
      let(:schema) do
        {
          name: 'test_target',
          desc: 'a basic transport',
          connection_info: {
            host: {
              type: 'String',
              desc: 'the host ip address or hostname',
            },
          },
        }
      end

      before(:each) do
        described_class.register(schema)
      end

      it { expect(described_class.list['test_target'].definition).to eq schema }
      it 'returns a new object' do
        expect(described_class.list['test_target'].definition.object_id).not_to eq schema.object_id
      end
    end
  end

  describe '#connect(name, connection_info)', agent_test: true do
    let(:name) { 'test_target' }
    let(:schema) do
      {
        name: 'test_target',
        desc: 'a basic transport',
        connection_info: {
          host: {
            type: 'String',
            desc: 'the host ip address or hostname',
          },
        },
      }
    end

    context 'when the transport file does not exist' do
      it 'throws a LoadError' do
        expect(described_class).to receive(:validate).with(name, host: 'example.com')
        expect { described_class.connect(name, host: 'example.com') }.to raise_error LoadError, %r{(no such file to load|cannot load such file) -- puppet/transport/test_target}
      end
    end

    context 'when the transport file does exist' do
      context 'with an incorrectly defined transport' do
        it 'throws a NameError' do
          described_class.register(schema)

          expect(described_class).to receive(:validate).with(name, host: 'example.com')
          expect(described_class).to receive(:require).with('puppet/transport/test_target')
          expect { described_class.connect(name, host: 'example.com') }.to raise_error NameError,
                                                                                       %r{uninitialized constant (Puppet::Transport|TestTarget)}
        end
      end

      context 'with a correctly defined transport' do
        let(:test_target) { double('Puppet::Transport::TestTarget') } # rubocop:disable RSpec/VerifiedDoubles
        let(:context) { instance_double(Puppet::ResourceApi::PuppetContext, 'context') }

        it 'loads initiates the class successfully' do
          described_class.register(schema)

          allow(described_class).to receive(:require).with('puppet/resource_api/puppet_context').and_call_original
          expect(described_class).to receive(:require).with('puppet/transport/test_target')
          expect(described_class).to receive(:validate).with(name, host: 'example.com')
          expect(Puppet::ResourceApi::PuppetContext).to receive(:new).with(kind_of(Puppet::ResourceApi::TransportSchemaDef)).and_return(context)

          stub_const('Puppet::Transport::TestTarget', test_target)
          expect(test_target).to receive(:new).with(context, host: 'example.com')

          described_class.connect(name, host: 'example.com')
        end
      end
    end
  end

  describe '#validate(name, connection_info)', agent_test: true do
    context 'when the transport being validated has not be registered' do
      it { expect { described_class.validate('wibble', {}) }.to raise_error LoadError, %r{(no such file to load|cannot load such file) -- puppet/transport/schema/wibble} }
    end

    context 'when the transport being validated has been registered' do
      let(:schema) { { name: 'validate', desc: 'a  minimal connection', connection_info: {} } }
      let(:schema_def) { instance_double('Puppet::ResourceApi::TransportSchemaDef', 'schema_def') }

      it 'validates the connection_info' do
        allow(Puppet::ResourceApi::TransportSchemaDef).to receive(:new).with(schema).and_return(schema_def)

        described_class.register(schema)

        expect(schema_def).to receive(:check_schema).with('connection_info').and_return(nil)
        expect(schema_def).to receive(:validate).with('connection_info').and_return(nil)

        described_class.validate('validate', 'connection_info')
      end
    end
  end
end
