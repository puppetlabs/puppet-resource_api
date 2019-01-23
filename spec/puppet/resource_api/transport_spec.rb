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

  context 'when connecting to a transport' do
    let(:name) { 'test_target' }
    let(:connection_info) do
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
      it 'throws a DevError' do
        expect(described_class).to receive(:validate).with(name, connection_info)
        expect { described_class.connect(name, connection_info) }.to raise_error Puppet::DevError,
                                                                                 %r{Cannot load transport for `test_target`}
      end
    end

    context 'when the transport file does exist' do
      context 'with an incorrectly defined transport' do
        it 'throws a DevError' do
          expect(described_class).to receive(:validate).with(name, connection_info)
          expect(described_class).to receive(:require).with('puppet/transport/test_target')
          expect { described_class.connect(name, connection_info) }.to raise_error Puppet::DevError,
                                                                                   %r{uninitialized constant (Puppet::Transport|TestTarget)}
        end
      end

      context 'with a correctly defined transport' do
        let(:test_target) { double('Puppet::Transport::TestTarget') } # rubocop:disable RSpec/VerifiedDoubles

        it 'loads initiates the class successfully' do
          expect(described_class).to receive(:require).with('puppet/transport/test_target')
          expect(described_class).to receive(:validate).with(name, connection_info)

          stub_const('Puppet::Transport::TestTarget', test_target)
          expect(test_target).to receive(:new).with(connection_info)

          described_class.connect(name, connection_info)
        end
      end
    end
  end

  describe '#self.validate' do
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
