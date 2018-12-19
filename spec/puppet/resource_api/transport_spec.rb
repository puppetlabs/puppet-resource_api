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
      it { expect { described_class.register(schema) }.to raise_error(Puppet::DevError, %r{`minimal` is already registered}) }
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
            type: 'Sensitive[String]',
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
