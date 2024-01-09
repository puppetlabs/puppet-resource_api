# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock

require 'spec_helper'

RSpec.describe Puppet::ResourceApi::Transport do
  def change_environment(name = nil)
    environment = class_double(Puppet::Node::Environment)

    if name.nil?
      allow(Puppet).to receive(:respond_to?).with(:lookup).and_return(false)
    else
      allow(Puppet).to receive(:respond_to?).with(:lookup).and_return(true)
    end

    allow(Puppet).to receive(:lookup).with(:current_environment).and_return(environment)

    # allow clean up scripts to run unhindered
    allow(Puppet).to receive(:lookup).with(:root_environment).and_call_original
    allow(Puppet).to receive(:lookup).with(:environments).and_call_original

    allow(environment).to receive(:name).and_return(name)
  end

  let(:strict_level) { :error }

  before do
    # set default to strictest setting
    # by default Puppet runs at warning level
    Puppet.settings[:strict] = strict_level
    # Enable debug logging
    Puppet.debug = true
  end

  describe '#register(schema)' do
    describe 'validation checks' do
      it { expect { described_class.register([]) }.to raise_error(Puppet::DevError, /requires a hash as schema/) }
      it { expect { described_class.register({}) }.to raise_error(Puppet::DevError, /requires a `:name`/) }
      it { expect { described_class.register(name: 'no connection info', desc: 'some description') }.to raise_error(Puppet::DevError, /requires `:connection_info`/) }
      it { expect { described_class.register(name: 'no description') }.to raise_error(Puppet::DevError, /requires `:desc`/) }

      it {
        expect do
          described_class.register(name: 'no hash connection_info',
                                   desc: 'some description',
                                   connection_info: [])
        end.to raise_error(Puppet::DevError, /`:connection_info` must be a hash, not/)
      }

      it {
        expect(described_class.register(name: 'no array connection_info_order',
                                        desc: 'some description',
                                        connection_info: {}).definition).to have_key(:connection_info_order)
      }

      it {
        expect(described_class.register(name: 'no array connection_info_order',
                                        desc: 'some description',
                                        connection_info: {}).definition[:connection_info_order]).to eq []
      }

      it {
        expect do
          described_class.register(name: 'no array connection_info_order',
                                   desc: 'some description',
                                   connection_info: {},
                                   connection_info_order: {})
        end.to raise_error(Puppet::DevError, /`:connection_info_order` must be an array, not/)
      }
    end

    context 'when registering a minimal transport' do
      let(:schema) { { name: 'minimal', desc: 'a  minimal connection', connection_info: {} } }

      it { expect { described_class.register(schema) }.not_to raise_error }

      context 'when re-registering a transport' do
        it {
          described_class.register(schema)
          expect { described_class.register(schema) }.to raise_error(Puppet::DevError, /`minimal` is already registered/)
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
              desc: 'the host ip address or hostname'
            },
            user: {
              type: 'String',
              desc: 'the user to connect as'
            },
            password: {
              type: 'String',
              sensitive: true,
              desc: 'the password to make the connection'
            }
          }
        }
      end

      context 'when a environment is available' do
        before { change_environment('production') }

        it 'adds to the transports register' do
          expect { described_class.register(schema) }.not_to raise_error
        end
      end

      context 'when no environment is available' do
        before { change_environment(nil) }

        it 'adds to the transports register' do
          expect { described_class.register(schema) }.not_to raise_error
        end
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
              desc: 'the host ip address or hostname'
            }
          }
        }
      end

      it {
        expect { described_class.register(schema) }.to raise_error(
          Puppet::DevError, /<garbage> is not a valid type specification/
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
              desc: 'the host ip address or hostname'
            }
          }
        }
      end

      before do
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
            desc: 'the host ip address or hostname'
          }
        }
      }
    end

    context 'when the transport file does not exist' do
      it 'throws a LoadError' do
        expect(described_class).to receive(:validate).with(name, { host: 'example.com' })
        expect { described_class.connect(name, host: 'example.com') }.to raise_error LoadError, %r{(no such file to load|cannot load such file) -- puppet/transport/test_target}
      end
    end

    context 'when the transport file does exist' do
      context 'with an incorrectly defined transport' do
        it 'throws a NameError' do
          described_class.register(schema)

          expect(described_class).to receive(:validate).with(name, { host: 'example.com' })
          expect(described_class).to receive(:require).with('puppet/transport/test_target')
          expect { described_class.connect(name, { host: 'example.com' }) }.to raise_error NameError,
                                                                                           /uninitialized constant (Puppet::Transport|TestTarget)/
        end
      end

      context 'with a correctly defined transport' do
        let(:test_target) { double('Puppet::Transport::TestTarget') } # rubocop:disable RSpec/VerifiedDoubles
        let(:context) { instance_double(Puppet::ResourceApi::PuppetContext, 'context') }

        it 'loads initiates the class successfully' do
          described_class.register(schema)

          allow(described_class).to receive(:require).with('puppet/resource_api/puppet_context').and_call_original
          expect(described_class).to receive(:require).with('puppet/transport/test_target')
          expect(described_class).to receive(:validate).with(name, { host: 'example.com' })
          allow(Puppet::ResourceApi::PuppetContext).to receive(:new).with(kind_of(Puppet::ResourceApi::TransportSchemaDef)).and_return(context)
          expect(Puppet::ResourceApi::PuppetContext).to receive(:new).with(kind_of(Puppet::ResourceApi::TransportSchemaDef))

          stub_const('Puppet::Transport::TestTarget', test_target)
          expect(test_target).to receive(:new).with(context, { host: 'example.com' })

          described_class.connect(name, { host: 'example.com' })
        end
      end
    end
  end

  describe '#inject_device(name, transport)' do
    let(:device_name) { 'wibble' }
    let(:transport) { instance_double(Puppet::Transport::Wibble, 'transport') }
    let(:wrapper) { instance_double(Puppet::ResourceApi::Transport::Wrapper, 'wrapper') }

    before do
      module Puppet::Transport
        class Wibble; end
      end
    end

    after do
      Puppet::Util::NetworkDevice.instance_variable_set(:@current, nil)
    end

    context 'when puppet has set_device' do
      it 'wraps the transport and calls set_device within NetworkDevice' do
        allow(Puppet::ResourceApi::Transport::Wrapper).to receive(:new).with(device_name, transport).and_return(wrapper)
        expect(Puppet::ResourceApi::Transport::Wrapper).to receive(:new).with(device_name, transport)
        allow(Puppet::Util::NetworkDevice).to receive(:respond_to?).with(:set_device).and_return(true)
        expect(Puppet::Util::NetworkDevice).to receive(:set_device).with(device_name, wrapper)

        described_class.inject_device(device_name, transport)
      end
    end

    context 'when puppet does not have set_device' do
      it 'wraps the transport and sets it as current in NetworkDevice' do
        allow(Puppet::ResourceApi::Transport::Wrapper).to receive(:new).with(device_name, transport).and_return(wrapper)
        expect(Puppet::ResourceApi::Transport::Wrapper).to receive(:new).with(device_name, transport)
        allow(Puppet::Util::NetworkDevice).to receive(:respond_to?).with(:set_device).and_return(false)
        expect(Puppet::Util::NetworkDevice).to receive(:respond_to?).with(:set_device)

        described_class.inject_device(device_name, transport)

        expect(Puppet::Util::NetworkDevice.current).to eq(wrapper)
      end
    end
  end

  describe '#validate(name, connection_info)', agent_test: true do
    context 'when the transport does not exist' do
      it { expect { described_class.send(:validate, 'wibble', {}) }.to raise_error LoadError, %r{(no such file to load|cannot load such file) -- puppet/transport/schema/wibble} }
    end

    context 'when the transport being validated has not be registered' do
      it 'throws an unregistered error message' do
        expect(described_class).to receive(:require).with('puppet/transport/schema/wibble')
        expect { described_class.send(:validate, 'wibble', {}) }.to raise_error Puppet::DevError, %r{ not registered with }
      end
    end

    context 'with a registered transport' do
      let(:attributes) { {} }
      let(:schema) { { name: 'validate', desc: 'a  minimal connection', connection_info: attributes } }
      let(:schema_def) { instance_double('Puppet::ResourceApi::TransportSchemaDef', 'schema_def') }
      let(:context) { instance_double(Puppet::ResourceApi::PuppetContext, 'context') }

      before do
        allow(Puppet::ResourceApi::TransportSchemaDef).to receive(:new).with(schema).and_return(schema_def)
        allow(schema_def).to receive(:attributes).with(no_args).and_return(attributes)
        allow(schema_def).to receive(:name).with(no_args).and_return(schema[:name])
        allow(described_class).to receive(:get_context).with('validate').and_return(context)

        described_class.register(schema)
      end

      it 'validates the connection_info' do
        expect(described_class).not_to receive(:require).with('puppet/transport/schema/validate')
        allow(schema_def).to receive(:check_schema).with({}, kind_of(String)).and_return(nil)
        expect(schema_def).to receive(:check_schema).with({}, kind_of(String))
        allow(schema_def).to receive(:validate).with({}).and_return(nil)
        expect(schema_def).to receive(:validate).with({})

        described_class.send :validate, 'validate', {}
      end

      context 'when validating bolt _target information' do
        let(:attributes) { { host: {}, foo: {} } }

        it 'cleans the connection_info' do
          allow(schema_def).to receive(:check_schema).with({ host: 'host value', foo: 'foo value' }, kind_of(String)).and_return(nil)
          expect(schema_def).to receive(:check_schema).with({ host: 'host value', foo: 'foo value' }, kind_of(String))
          allow(schema_def).to receive(:validate).with({ host: 'host value', foo: 'foo value' }).and_return(nil)
          expect(schema_def).to receive(:validate).with({ host: 'host value', foo: 'foo value' })

          expect(context).to receive(:debug).with('Discarding bolt metaparameter: query')
          expect(context).to receive(:debug).with('Discarding bolt metaparameter: remote-transport')
          expect(context).to receive(:debug).with('Discarding bolt metaparameter: remote-reserved')
          expect(context).to receive(:info).with('Discarding superfluous bolt attribute: user')
          expect(context).to receive(:warning).with('Discarding unknown attribute: bar')
          described_class.send :validate, 'validate', 'remote-transport': 'validate',
                                                      host: 'host value',
                                                      foo: 'foo value',
                                                      user: 'superfluous bolt value',
                                                      query: 'metaparameter value',
                                                      'remote-reserved': 'reserved value',
                                                      bar: 'unknown attribute'
        end
      end

      context 'when applying defaults' do
        let(:attributes) { { host: { default: 'example.com' }, port: { default: 443 } } }

        it 'sets defaults in the connection info' do
          allow(schema_def).to receive(:check_schema).with({ host: 'host value', port: 443 }, kind_of(String)).and_return(nil)
          expect(schema_def).to receive(:check_schema).with({ host: 'host value', port: 443 }, kind_of(String))
          allow(schema_def).to receive(:validate).with({ host: 'host value', port: 443 }).and_return(nil)
          expect(schema_def).to receive(:validate).with({ host: 'host value', port: 443 })

          expect(context).to receive(:debug).with('Using default value for attribute: port, value: 443')
          described_class.send :validate, 'validate', host: 'host value'
        end
      end
    end
  end

  describe '#wrap_sensitive(name, connection_info)' do
    let(:schema) do
      {
        name: 'sensitive_transport',
        desc: 'a  secret',
        connection_info: {
          secret: {
            type: 'String',
            desc: 'A secret to protect.',
            sensitive: true
          }
        }
      }
    end
    let(:schema_def) { instance_double('Puppet::ResourceApi::TransportSchemaDef', 'schema_def') }

    before do
      allow(Puppet::ResourceApi::TransportSchemaDef).to receive(:new).with(schema).and_return(schema_def)
      described_class.register(schema)
    end

    context 'when the connection info contains a `Sensitive` type' do
      let(:connection_info) do
        {
          secret: 'sup3r_secret_str1ng'
        }
      end

      it 'wraps the value in a PSensitiveType' do
        allow(schema_def).to receive(:definition).and_return(schema)

        conn_info = described_class.send :wrap_sensitive, 'sensitive_transport', connection_info
        expect(conn_info[:secret]).to be_a(Puppet::Pops::Types::PSensitiveType::Sensitive)
        expect(conn_info[:secret].unwrap).to eq('sup3r_secret_str1ng')
      end
    end

    context 'when the connection info does not contain a `Sensitive` type' do
      let(:connection_info) { {} }

      it 'wraps the value in a PSensitiveType' do
        allow(schema_def).to receive(:definition).and_return(schema)

        conn_info = described_class.send :wrap_sensitive, 'sensitive_transport', connection_info
        expect(conn_info[:secret]).to be_nil
      end
    end
  end
end

# rubocop:enable Lint/ConstantDefinitionInBlock
