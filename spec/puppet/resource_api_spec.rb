require 'spec_helper'

RSpec.describe Puppet::ResourceApi do
  let(:strict_level) { :error }
  let(:log_sink) { [] }

  before(:each) do
    # set default to strictest setting
    # by default Puppet runs at warning level
    Puppet.settings[:strict] = strict_level
    # Enable debug logging
    Puppet.debug = true

    Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(log_sink))
  end

  after(:each) do
    Puppet::Util::Log.close_all
  end

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
      it { expect(type.apply_to).to eq(:host) }
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
          test_enum: {
            type: 'Enum[a, b, c]',
            desc: 'an enumeration',
          },
          test_variant_pattern: {
            type: 'Variant[Pattern[/\A(0x)?[0-9a-fA-F]{8}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{16}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{40}\Z/]]',
            desc: 'a pattern value',
          },
          test_url: {
            type: 'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]',
            desc: 'a hkp or http(s) url',
          },
          test_optional_string: {
            type: 'Optional[String]',
            desc: 'a optional string value',
          },
        },
        autorequire: {
          var: '$test_string',
        },
        autobefore: {
          const: 'value',
        },
        autosubscribe: {
          list: %w[foo bar],
        },
        autonotify: {
          mixed: [10, '$test_integer'],
        },
      }
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:with_string) }

      it { is_expected.not_to be_nil }
      it { expect(type.properties.first.doc).to match %r{the description} }
      it { expect(type.properties.first.name).to eq :test_string }

      def extract_values(function)
        result = []
        type.send(function) do |_type, values|
          # rely on the fact that the resource api is doing `self[]` internally to find the value
          # see https://github.com/puppetlabs/puppet/blob/9f2c143962803a72c68f35be3462944e851bcdce/lib/puppet/type.rb#L2143
          # for details
          result += { test_string: 'foo', test_integer: 100 }.instance_eval(&values)
        end
        result
      end

      describe 'autorequire' do
        it('yields the block for `var`') { expect { |b| type.eachautorequire(&b) }.to yield_with_args(:var, be_a(Proc)) }
        it 'the yielded block returns the `test_string` value' do
          expect(extract_values(:eachautorequire)).to eq ['foo']
        end
      end

      describe 'autobefore' do
        it('yields the block for `const`') { expect { |b| type.eachautobefore(&b) }.to yield_with_args(:const, be_a(Proc)) }
        it('the yielded block returns the constant "value"') do
          expect(extract_values(:eachautobefore)).to eq ['value']
        end
      end

      describe 'autosubscribe' do
        it('yields the block for `list`') { expect { |b| type.eachautosubscribe(&b) }.to yield_with_args(:list, be_a(Proc)) }
        it('the yielded block returns the multiple values') do
          expect(extract_values(:eachautosubscribe)).to eq %w[foo bar]
        end
      end

      describe 'autonotify' do
        it('yields the block for `mixed`') { expect { |b| type.eachautonotify(&b) }.to yield_with_args(:mixed, be_a(Proc)) }
        it('the yielded block returns multiple integer values') do
          expect(extract_values(:eachautonotify)).to eq [10, 100]
        end
      end
    end

    describe 'an instance of this type' do
      subject(:instance) { Puppet::Type.type(:with_string).new(params) }

      let(:params) do
        { title: 'test', test_boolean: true, test_integer: 15, test_float: 1.23,
          test_enum: 'a', test_variant_pattern: '0xAEF123FF', test_url: 'http://example.com' }
      end

      it('uses defaults correctly') { expect(instance[:test_string]).to eq 'default value' }

      context 'when setting values for the attributes' do
        let(:params) do
          {
            title: 'test',
            test_string: 'somevalue',
            test_boolean: true,
            test_integer: -1,
            test_float: -1.5,
            test_enum: 'a',
            test_variant_pattern: 'a' * 8,
            test_url: 'hkp://example.com',
          }
        end

        it('the test_string value is set correctly') { expect(instance[:test_string]).to eq 'somevalue' }
        it('the test_integer value is set correctly') { expect(instance[:test_integer]).to eq(-1) }
        it('the test_float value is set correctly') { expect(instance[:test_float]).to eq(-1.5) }
        it('the test_variant_pattern value is set correctly') { expect(instance[:test_variant_pattern]).to eq('a' * 8) }
        it('the test_url value is set correctly') { expect(instance[:test_url]).to eq('hkp://example.com') }
      end

      context 'when setting string values for the attributes' do
        let(:params) do
          {
            title: 'test',
            test_string: 'somevalue',
            test_boolean: 'true',
            test_integer: '-1',
            test_float: '-1.5',
            test_enum: 'a',
            test_variant_pattern: 'a' * 8,
            test_url: 'hkp://example.com',
          }
        end

        it('the test_string value is set correctly') { expect(instance[:test_string]).to eq 'somevalue' }
        it('the test_integer value is set correctly') { expect(instance[:test_integer]).to eq(-1) }
        it('the test_float value is set correctly') { expect(instance[:test_float]).to eq(-1.5) }
        it('the test_enum value is set correctly') { expect(instance[:test_enum]).to eq('a') }
        it('the test_variant_pattern value is set correctly') { expect(instance[:test_variant_pattern]).to eq('a' * 8) }
        it('the test_url value is set correctly') { expect(instance[:test_url]).to eq('hkp://example.com') }
      end

      describe 'different boolean values' do
        let(:params) do
          {
            title: 'test',
            test_string: 'somevalue',
            test_boolean: the_boolean,
            test_integer: '-1',
            test_float: '-1.5',
            test_enum: 'a',
            test_variant_pattern: 'a' * 8,
            test_url: 'http://example.com',
          }
        end

        # rubocop:disable Lint/BooleanSymbol
        context 'when using :true' do
          let(:the_boolean) { :true }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq :true }
        end
        context 'when using :false' do
          let(:the_boolean) { :false }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq :false }
        end
        context 'when using "true"' do
          let(:the_boolean) { 'true' }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq :true }
        end
        context 'when using "false"' do
          let(:the_boolean) { 'false' }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq :false }
        end
        context 'when using true' do
          let(:the_boolean) { true }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq :true }
        end
        context 'when using false' do
          let(:the_boolean) { false }

          it('the test_boolean value is set correctly') { expect(instance[:test_boolean]).to eq :false }
        end
        context 'when using an unparsable value' do
          let(:the_boolean) { 'flubb' }

          it('the test_boolean value is set correctly') { expect { instance }.to raise_error Puppet::ResourceError, %r{test_boolean expect.* Boolean .* got String} }
        end
        # rubocop:enable Lint/BooleanSymbol
      end

      context 'with a basic provider', agent_test: true do
        let(:provider_class) do
          Class.new do
            def get(_context)
              []
            end

            def set(_context, _changes); end
          end
        end

        before(:each) do
          stub_const('Puppet::Provider::WithString', Module.new)
          stub_const('Puppet::Provider::WithString::WithString', provider_class)
        end

        context 'when mandatory attributes are missing' do
          let(:params) do
            {
              title: 'test',
            }
          end

          it {
            expect {
              instance.validate
              instance.retrieve
            }.not_to raise_exception }
        end
      end
    end
  end

  context 'when registering a type that is ensurable', agent_test: true do
    context 'when ensurable is correctly declared' do
      let(:definition) do
        {
          name: 'with_ensure',
          attributes: {
            name: {
              type: 'String',
              behaviour: :namevar,
              desc: 'the title',
            },
            ensure: {
              type: 'Enum[present, absent]',
              desc: 'a ensure value',
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
            test_enum: {
              type: 'Enum[a, b, c]',
              desc: 'an enumeration',
            },
            test_variant_pattern: {
              type: 'Variant[Pattern[/\A(0x)?[0-9a-fA-F]{8}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{16}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{40}\Z/]]',
              desc: 'a pattern value',
            },
            test_url: {
              type: 'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]',
              desc: 'a hkp or http(s) url',
            },
            test_optional_string: {
              type: 'Optional[String]',
              desc: 'a optional string value',
            },
          },
        }
      end

      let(:provider_class) do
        Class.new do
          def get(_context)
            []
          end

          def set(_context, _changes); end
        end
      end

      it { expect { described_class.register_type(definition) }.not_to raise_error }

      describe 'the registered type' do
        subject(:type) { Puppet::Type.type(:with_ensure) }

        it { is_expected.not_to be_nil }
      end

      before(:each) do
        stub_const('Puppet::Provider::WithEnsure', Module.new)
        stub_const('Puppet::Provider::WithEnsure::WithEnsure', provider_class)
      end

      describe 'an instance of this type' do
        subject(:instance) { Puppet::Type.type(:with_ensure).new(params) }

        context 'when mandatory attributes are missing, but ensure is present' do
          let(:params) do
            {
              title: 'test',
              ensure: 'present',
            }
          end

          it {
            expect {
              instance.validate
              instance.retrieve
            }.to raise_exception Puppet::ResourceError, %r{The following mandatory attributes were not provided} }
        end

        describe 'an absent instance' do
          subject(:retrieved_info) do
            instance.validate
            instance.retrieve
          end

          let(:params) do
            {
              title: 'does_not_exist',
            }
          end

          it('its name is set correctly') { expect(retrieved_info[:name]).to eq 'does_not_exist' }
          it('its properties are set correctly') {
            expect(retrieved_info[:test_string]).to be_nil
          }
          it { expect(retrieved_info[:ensure]).to eq(:absent) }

          it { expect { retrieved_info }.not_to raise_exception }
        end

        context 'when setting values for the attributes' do
          let(:params) do
            {
              title: 'test',
              ensure: ensure_value,
              test_string: 'somevalue',
              test_boolean: true,
              test_integer: -1,
              test_float: -1.5,
              test_enum: 'a',
              test_variant_pattern: 'a' * 8,
              test_url: 'hkp://example.com',
            }
          end

          %w[absent present].each do |value|
            context "with ensure=#{value}" do
              let(:ensure_value) { value }

              it('the ensure value is presented as a symbol') { expect(instance[:ensure]).to eq ensure_value.to_sym }
              it('the ensure rs_value is a string') { expect(instance.parameters[:ensure].rs_value).to eq ensure_value }

              it { expect(instance.parameters[:ensure]).to be_insync(value) }
            end
          end
        end
      end
    end
    context 'when ensurable is not correctly declared' do
      let(:definition) do
        {
          name: 'with_bad_ensure',
          attributes: {
            name: {
              type: 'String',
              behaviour: :namevar,
              desc: 'the title',
            },
            ensure: {
              type: 'Enum[yes, no]',
              desc: 'a bad ensure attribute',
            },
          },
        }
      end

      it { expect { described_class.register_type(definition) }.to raise_error Puppet::DevError, %r{`:ensure` attribute must have a type of: `Enum\[present, absent\]`} }
    end
  end

  context 'when registering a type with multiple parameters' do
    let(:definition) do
      {
        name: 'with_parameters',
        attributes: {
          name: {
            type: 'String',
            behaviour: :namevar,
            desc: 'the title',
          },
          test_string: {
            type: 'String',
            desc: 'a string parameter',
            default: 'default value',
            behaviour: :parameter,
          },
          test_boolean: {
            type: 'Boolean',
            desc: 'a boolean parameter',
            behaviour: :parameter,
          },
          test_integer: {
            type: 'Integer',
            desc: 'an integer parameter',
            behaviour: :parameter,
          },
          test_float: {
            type: 'Float',
            desc: 'a floating point parameter',
            behaviour: :parameter,
          },
          test_variant_pattern: {
            type: 'Variant[Pattern[/\A(0x)?[0-9a-fA-F]{8}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{16}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{40}\Z/]]',
            desc: 'a pattern parameter',
            behaviour: :parameter,
          },
          test_url: {
            type: 'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]',
            desc: 'a hkp or http(s) url parameter',
            behaviour: :parameter,
          },
          test_optional_string: {
            type: 'Optional[String]',
            desc: 'a optional string parameter',
            behaviour: :parameter,
          },
        },
      }
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:with_parameters) }

      it { is_expected.not_to be_nil }
      it { expect(type.parameters[1]).to eq :test_string }
    end

    describe 'an instance of this type' do
      subject(:instance) { Puppet::Type.type(:with_parameters).new(params) }

      let(:params) do
        { title: 'test', test_boolean: true, test_integer: 15, test_float: 1.23,
          test_variant_pattern: '0xAEF123FF', test_url: 'http://example.com' }
      end

      it('uses defaults correctly') { expect(instance[:test_string]).to eq 'default value' }

      context 'when setting a value for the parameters' do
        let(:params) do
          {
            title: 'test',
            test_string: 'somevalue',
            test_boolean: 'true',
            test_integer: '-1',
            test_float: '-1.5',
            test_variant_pattern: 'a' * 8,
            test_url: 'hkp://example.com',
          }
        end

        it('the test_string value is set correctly') { expect(instance[:test_string]).to eq 'somevalue' }
        it('the test_integer value is set correctly') { expect(instance[:test_integer]).to eq(-1) }
        it('the test_float value is set correctly') { expect(instance[:test_float]).to eq(-1.5) }
        it('the test_variant_pattern value is set correctly') { expect(instance[:test_variant_pattern]).to eq('a' * 8) }
        it('the test_url value is set correctly') { expect(instance[:test_url]).to eq('hkp://example.com') }
      end

      context 'when mandatory parameters are missing' do
        let(:params) do
          {
            title: 'test',
          }
        end

        it { expect { instance }.to raise_exception Puppet::ResourceError, %r{The following mandatory parameters were not provided} }
      end
    end
  end

  context 'when registering an attribute with an optional data type' do
    let(:definition) do
      {
        name: 'no_type',
        attributes: {
          name: {
            type: 'Optional[Integer]',
            behaviour: :namevar,
          },
        },
      }
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:no_type) }

      it { is_expected.not_to be_nil }
      it { expect(type.parameters[0]).to eq :name }
    end
  end

  context 'when registering a type with a `behavior`' do
    let(:definition) do
      {
        name: 'behaviour',
        attributes: {
          name: {
            type: 'String',
            behavior: :namevar,
          },
        },
      }
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:behaviour) }

      it { is_expected.not_to be_nil }
      it { expect(type.parameters[0]).to eq :name }
    end
  end

  context 'when registering a type with an `init_only` attribute', agent_test: true do
    let(:definition) do
      {
        name: 'init_behaviour',
        attributes: {
          ensure: {
            type: 'Enum[present, absent]',
          },
          name: {
            type: 'String',
            behavior: :namevar,
          },
          immutable: {
            type: 'String',
            behaviour: :init_only,
          },
          mutable: {
            type: 'String',
          },
        },
      }
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:init_behaviour) }

      it { is_expected.not_to be_nil }
      it { expect(type.parameters[0]).to eq :name }
    end

    describe 'an instance of the type' do
      let(:provider_class) do
        Class.new do
          def get(_context)
            [{ name: 'init', ensure: 'present', immutable: 'physics', mutable: 'bank balance' }]
          end

          def set(_context, _changes); end
        end
      end

      before(:each) do
        stub_const('Puppet::Provider::InitBehaviour', Module.new)
        stub_const('Puppet::Provider::InitBehaviour::InitBehaviour', provider_class)
      end

      context 'when a manifest wants to set the value of an init_only attribute' do
        let(:instance) { Puppet::Type.type(:init_behaviour).new(name: 'new_init', ensure: 'present', immutable: 'new', mutable: 'flexible') }

        context 'when Puppet strict setting is :error' do
          let(:strict_level) { :error }

          it { expect { instance.flush }.not_to raise_error }
          it {
            expect(Puppet).not_to receive(:warning)
            instance.flush
          }
        end

        context 'when Puppet strict setting is :warning' do
          let(:strict_level) { :warning }

          it { expect { instance.flush }.not_to raise_error }
          it {
            expect(Puppet).not_to receive(:warning)
            instance.flush
          }
        end

        context 'when Puppet strict setting is :off' do
          let(:strict_level) { :off }

          it { expect { instance.flush }.not_to raise_error }
          it {
            expect(Puppet).not_to receive(:warning)
            instance.flush
          }
        end
      end

      context 'when a manifest wants to change the value of an init_only attribute' do
        let(:instance) { Puppet::Type.type(:init_behaviour).new(name: 'init', ensure: 'present', immutable: 'lies', mutable: 'overdraft') }

        context 'when Puppet strict setting is :error' do
          let(:strict_level) { :error }

          it { expect { instance.flush }.to raise_error Puppet::ResourceError, %r{Attempting to change `immutable` init_only attribute value from} }
        end

        context 'when Puppet strict setting is :warning' do
          let(:strict_level) { :warning }

          it {
            expect(Puppet).to receive(:warning).with(%r{Attempting to change `immutable` init_only attribute value from})
            instance.flush
          }
        end

        context 'when Puppet strict setting is :off' do
          let(:strict_level) { :off }

          it { expect { instance.flush }.not_to raise_error }
          it {
            expect(Puppet).not_to receive(:warning)
            instance.flush
          }
        end
      end
    end
  end

  context 'when registering a type with an `read_only` attribute', agent_test: true do
    let(:definition) do
      {
        name: 'read_only_behaviour',
        attributes: {
          ensure: {
            type: 'Enum[present, absent]',
          },
          name: {
            type: 'String',
            behavior: :namevar,
          },
          immutable: {
            type: 'String',
            behaviour: :read_only,
          },
        },
      }
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:read_only_behaviour) }

      it { is_expected.not_to be_nil }
      it { expect(type.parameters[0]).to eq :name }
    end

    describe 'an instance of the type' do
      let(:provider_class) do
        Class.new do
          def get(_context)
            [{ name: 'foo_ro', ensure: 'present', immutable: 'physics' }]
          end

          def set(_context, _changes); end
        end
      end

      before(:each) do
        stub_const('Puppet::Provider::ReadOnlyBehaviour', Module.new)
        stub_const('Puppet::Provider::ReadOnlyBehaviour::ReadOnlyBehaviour', provider_class)
      end

      context 'when a manifest wants to set the value of a read_only attribute' do
        let(:instance) { Puppet::Type.type(:read_only_behaviour).new(name: 'new_ro', ensure: 'present', immutable: 'new') }

        it { expect { instance.flush }.to raise_error Puppet::ResourceError, %r{Attempting to set `immutable` read_only attribute value to} }
      end

      context 'when a manifest wants to change the value of a read_only attribute' do
        let(:instance) { Puppet::Type.type(:read_only_behaviour).new(name: 'foo_ro', ensure: 'present', immutable: 'change') }

        it { expect { instance.flush }.to raise_error Puppet::ResourceError, %r{Attempting to set `immutable` read_only attribute value to} }
      end
    end
  end

  context 'when registering a type with a malformed attributes' do
    context 'without a type' do
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

    context 'with both behavior and behaviour' do
      let(:definition) do
        {
          name: 'bad_behaviour',
          attributes: {
            name: {
              behaviour: :namevar,
              behavior: :namevar,
            },
          },
        }
      end

      it { expect { described_class.register_type(definition) }.to raise_error Puppet::DevError, %r{name.*attribute has both} }
    end
  end

  context 'when registering a namevar that is not called `name`' do
    let(:definition) do
      {
        name: 'not_name_namevar',
        attributes: {
          not_name: {
            type: 'String',
            behaviour: :namevar,
            desc: 'the name',
          },
        },
      }
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'an instance of this type' do
      subject(:instance) { Puppet::Type.type(:not_name_namevar).new(params) }

      context 'with only a :title' do
        let(:params) { { title: 'test' } }

        it('the namevar is set to the title') { expect(instance[:not_name]).to eq 'test' }
      end

      context 'with only a :name' do
        let(:params) { { name: 'test' } }

        it('the namevar is set to the name') { expect(instance[:not_name]).to eq 'test' }
      end

      context 'with only the namevar' do
        let(:params) { { not_name: 'test' } }

        it('the namevar is set to the name') { expect(instance[:not_name]).to eq 'test' }
      end

      context 'with :title, and the namevar' do
        let(:params) { { title: 'some title', not_name: 'test' } }

        it('the namevar is set to the name') { expect(instance[:not_name]).to eq 'test' }
      end

      context 'with :name, and the namevar' do
        let(:params) { { name: 'some title', not_name: 'test' } }

        it('the namevar is set to the name') { expect(instance[:not_name]).to eq 'test' }
      end
    end

    describe 'a provider that does not return the namevar', agent_test: true do
      subject(:instance) { Puppet::Type.type(:not_name_namevar) }

      let(:provider_class) do
        Class.new do
          def get(_context)
            [{ name: 'some title' }]
          end

          def set(_context, changes) end
        end
      end

      before(:each) do
        stub_const('Puppet::Provider::NotNameNamevar', Module.new)
        stub_const('Puppet::Provider::NotNameNamevar::NotNameNamevar', provider_class)
      end

      it('throws an error') {
        expect {
          instance.instances
        }.to  raise_error Puppet::ResourceError, %r{^`not_name_namevar.get` did not return a value for the `not_name` namevar attribute$}
      }
    end
  end

  describe '#load_provider', agent_test: true do
    before(:each) { described_class.register_type(definition) }

    context 'when loading a non-existing provider' do
      let(:definition) { { name: 'does_not_exist', attributes: {} } }

      it { expect { described_class.load_provider('does_not_exist') }.to raise_error Puppet::DevError, %r{puppet/provider/does_not_exist/does_not_exist} }
    end

    context 'when loading a provider that doesn\'t create the correct class' do
      let(:definition) { { name: 'no_class', attributes: {} } }

      it { expect { described_class.load_provider('no_class') }.to raise_error Puppet::DevError, %r{NoClass} }
    end

    context 'when loading a provider that creates the correct class' do
      let(:definition) { { name: 'test_provider', attributes: {} } }

      it { expect(described_class.load_provider('test_provider').name).to eq 'Puppet::Provider::TestProvider::TestProvider' }
    end
  end

  context 'with a provider that does canonicalization', agent_test: true do
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
        def canonicalize(_context, resources)
          resources.map do |resource|
            result = resource.dup
            unless resource[:test_string] && resource[:test_string].start_with?('canon')
              result[:test_string] = ['canon', resource[:test_string]].compact.join
            end
            result
          end
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

    it 'is seen as a supported feature' do
      expect(Puppet).not_to receive(:warning).with(%r{Unknown feature detected:.*})
    end

    describe '#strict_check' do
      let(:type) { Puppet::Type.type(:canonicalizer) }
      let(:instance) { type.new(name: 'somename', test_string: 'foo') }

      context 'when current_state is not already canonicalized' do
        context 'when Puppet strict setting is :off' do
          let(:strict_level) { :off }

          it { expect(instance.strict_check(nil)).to be_nil }

          it 'will not log a warning message' do
            expect(Puppet).not_to receive(:warning)
            instance.strict_check(nil)
          end
        end

        context 'when Puppet strict setting is :error' do
          let(:strict_level) { :error }

          it 'will throw an exception' do
            expect {
              instance.strict_check({})
            }.to raise_error(Puppet::DevError, %r{has not provided canonicalized values})
          end
        end

        context 'when Puppet strict setting is :warning' do
          let(:strict_level) { :warning }

          it { expect(instance.strict_check({})).to be_nil }

          it 'will log warning message' do
            expect(Puppet).to receive(:warning).with(%r{has not provided canonicalized values})
            instance.strict_check({})
          end
        end
      end

      context 'when current_state is already canonicalized' do
        context 'when Puppet strict setting is :off' do
          let(:strict_level) { :off }

          it { expect(instance.strict_check(test_string: 'canon')).to be_nil }

          it 'will not log a warning message' do
            expect(Puppet).not_to receive(:warning)
            instance.strict_check(test_string: 'canon')
          end
        end

        context 'when Puppet strict setting is :error' do
          let(:strict_level) { :error }

          it 'will throw an exception' do
            expect { instance.strict_check(test_string: 'canon') }.not_to raise_error
          end
        end

        context 'when Puppet strict setting is :warning' do
          let(:strict_level) { :warning }

          it { expect(instance.strict_check(test_string: 'canon')).to be_nil }

          it 'will not log a warning message' do
            expect(Puppet).not_to receive(:warning)
            instance.strict_check(test_string: 'canon')
          end
        end
      end

      context 'when canonicalize modifies current_state' do
        let(:strict_level) { :error }

        before(:each) do
          allow(instance.my_provider).to receive(:canonicalize) do |_context, resources|
            resources[0][:test_string] = 'canontest'
            resources
          end
        end
        it 'stills raise an error' do
          expect {
            instance.strict_check({})
          }.to raise_error(Puppet::Error, %r{has not provided canonicalized values})
        end
      end
    end

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
            Puppet.debug = true
            instance.flush
            puts log_sink(&:message).inspect
          end

          after(:each) do
            Puppet.debug = false
          end

          context 'with no changes' do
            it('set will not be called') do
              expect(instance.my_provider.last_changes).to be_nil
              expect(log_sink.last.message).to eq('Current State: {:name=>"somename", :test_string=>"canonfoo"}')
            end
          end

          context 'with a change' do
            let(:test_string) { 'bar' }

            it('set will be called with the correct structure') do
              expect(instance.my_provider.last_changes).to eq('somename' => {
                                                                is: { name: 'somename', test_string: 'canonfoo' },
                                                                should: { name: 'somename', test_string: 'canonbar' },
                                                              })
            end

            it 'logs correctly' do
              expect(log_sink.map(&:message)).to include(
                'Current State: {:name=>"somename", :test_string=>"canonfoo"}',
                'Target State: {:name=>"somename", :test_string=>"canonbar"}',
              )
            end
          end
        end
      end

      context 'when retrieving instances through `get`' do
        it('instances returns an Array') { expect(type.instances).to be_a Array }
        it('returns an array of TypeShims') { expect(type.instances[0]).to be_a Puppet::ResourceApi::TypeShim }
        it('its name is set correctly') { expect(type.instances[0].name).to eq 'somename' }
      end

      context 'when retrieving an instance through `retrieve`' do
        let(:resource) { instance.retrieve }

        before(:each) do
          Puppet.debug = true
        end

        after(:each) do
          Puppet.debug = false
        end

        describe 'an existing instance' do
          let(:instance) { type.new(name: 'somename') }

          it('its name is set correctly') { expect(resource[:name]).to eq 'somename' }
          it('its properties are set correctly') do
            expect(resource[:test_string]).to eq 'canonfoo'
            expect(log_sink.last.message).to eq('Current State: {:name=>"somename", :test_string=>"canonfoo"}')
          end
        end
      end
    end
  end

  context 'with a provider that does not need canonicalization', agent_test: true do
    let(:definition) do
      {
        name: 'passthrough',
        attributes: {
          name: {
            type: 'String',
            behaviour: :namevar,
          },
          test_string: {
            type: 'String',
          },
        },
      }
    end
    let(:provider_class) do
      Class.new do
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
      stub_const('Puppet::Provider::Passthrough', Module.new)
      stub_const('Puppet::Provider::Passthrough::Passthrough', provider_class)
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:passthrough) }

      before(:each) do
        allow(type.my_provider).to receive(:get)
          .with(kind_of(Puppet::ResourceApi::BaseContext))
          .and_return([{ name: 'somename', test_string: 'foo' },
                       { name: 'other', test_string: 'bar' }])
      end

      it { is_expected.not_to be_nil }

      context 'when manually creating an instance' do
        let(:test_string) { 'foo' }
        let(:instance) { type.new(name: 'somename', test_string: test_string) }

        it('its provider class') { expect(instance.my_provider).not_to be_nil }

        context 'when flushing' do
          before(:each) do
            Puppet.debug = true
            instance.flush
          end

          after(:each) do
            Puppet.debug = false
          end

          context 'with no changes' do
            it('set will not be called') do
              expect(instance.my_provider.last_changes).to be_nil
              expect(log_sink.last.message).to eq('Current State: {:name=>"somename", :test_string=>"foo"}')
            end
          end

          context 'with a change' do
            let(:test_string) { 'bar' }

            it('set will be called with the correct structure') do
              expect(instance.my_provider.last_changes).to eq('somename' => {
                                                                is: { name: 'somename', test_string: 'foo' },
                                                                should: { name: 'somename', test_string: 'bar' },
                                                              })

              expect(log_sink.map(&:message)).to include(
                'Current State: {:name=>"somename", :test_string=>"foo"}',
                'Target State: {:name=>"somename", :test_string=>"bar"}',
              )
            end
          end
        end
      end

      context 'when retrieving instances through `get`' do
        it('instances returns an Array') { expect(type.instances).to be_a Array }
        it('returns an array of TypeShims') { expect(type.instances[0]).to be_a Puppet::ResourceApi::TypeShim }
        it('its name is set correctly') { expect(type.instances[0].name).to eq 'somename' }
      end

      context 'when retrieving an instance through `retrieve`' do
        let(:resource) { instance.retrieve }

        before(:each) do
          Puppet.debug = true
        end

        after(:each) do
          Puppet.debug = false
        end

        describe 'an existing instance' do
          let(:instance) { type.new(name: 'somename', test_string: 'foo') }

          it('its name is set correctly') { expect(resource[:name]).to eq 'somename' }
          it('its properties are set correctly') do
            expect(resource[:test_string]).to eq 'foo'
            expect(log_sink.last.message).to eq('Current State: {:name=>"somename", :test_string=>"foo"}')
          end
          context 'when strict checking is on' do
            it('will not throw') {
              Puppet.settings[:strict] = :error
              expect { described_class.register_type(definition) }.not_to raise_error
            }
          end
        end
      end
    end
  end

  context 'with a `remote_resource` provider', agent_test: true do
    let(:definition) do
      {
        name: 'remoter',
        attributes: {
          name: {
            type: 'String',
            behaviour: :namevar,
          },
          test_string: {
            type: 'String',
          },
        },
        features: ['remote_resource'],
      }
    end
    let(:provider_class) { instance_double('Class', 'provider_class') }
    let(:provider) { instance_double('Puppet::Provider::Remoter::Remoter', 'provider_instance') }

    before(:each) do
      stub_const('Puppet::Provider::Remoter', Module.new)
      stub_const('Puppet::Provider::Remoter::Remoter', provider_class)
      allow(provider_class).to receive(:new).and_return(provider)
      Puppet.settings[:strict] = :warning
    end

    it 'is seen as a supported feature' do
      expect(Puppet).not_to receive(:warning).with(%r{Unknown feature detected:.*remote_resource})
      expect { described_class.register_type(definition) }.not_to raise_error
    end

    describe 'the registered type' do
      subject(:type) { Puppet::Type.type(:remoter) }

      it { is_expected.not_to be_nil }
      it { expect(type.apply_to).to eq(:device) }

      it 'returns true for feature_support?' do
        expect(type.context.type).to be_feature('remote_resource')
      end
    end
  end

  context 'with a `supports_noop` provider', agent_test: true do
    let(:definition) do
      {
        name: 'test_noop_support',
        features: ['supports_noop'],
        attributes:   {
          ensure:      {
            type:    'Enum[present, absent]',
            default: 'present',
          },
          name:        {
            type:      'String',
            behaviour: :namevar,
          },
        },
      }
    end
    let(:type) { Puppet::Type.type(:test_noop_support) }
    let(:provider_class) do
      # Hide the `noop:` kwarg from older jruby, which is still on ruby-1.9 syntax.
      eval(<<CODE, binding, __FILE__, __LINE__ + 1)
        Class.new do
          def get(_context)
            []
          end

          def set(_context, _changes, noop: false); end
        end
CODE
    end
    let(:provider) { instance_double('Puppet::Provider::TestNoopSupport::TestNoopSupport', 'provider') }

    before(:each) do
      stub_const('Puppet::Provider::TestNoopSupport', Module.new)
      stub_const('Puppet::Provider::TestNoopSupport::TestNoopSupport', provider_class)
      allow(provider_class).to receive(:new).and_return(provider)
      allow(provider).to receive(:get).and_return([])
    end

    it 'is seen as a supported feature' do
      expect(Puppet).not_to receive(:warning).with(%r{Unknown feature detected:.*supports_noop})
      expect { described_class.register_type(definition) }.not_to raise_error
    end

    describe 'flush getting called in noop mode' do
      it 'set gets called with noop:true' do
        expect(provider).to receive(:set).with(anything, anything, noop: true)
        instance = type.new(name: 'test', ensure: 'present', noop: true)
        instance.flush
      end
    end
  end

  context 'with a `simple_get_filter` provider', agent_test: true do
    let(:definition) do
      {
        name: 'test_simple_get_filter',
        features: ['simple_get_filter'],
        attributes:   {
          ensure:      {
            type:    'Enum[present, absent]',
            default: 'present',
          },
          name:        {
            type:      'String',
            behaviour: :namevar,
          },
        },
      }
    end
    let(:type) { Puppet::Type.type(:test_simple_get_filter) }
    let(:provider_class) do
      Class.new do
        def get(_context, _names = nil)
          []
        end

        def set(_context, changes) end
      end
    end
    let(:provider) { instance_double('Puppet::Provider::TestSimpleGetFilter::TestSimpleGetFilter', 'provider') }

    before(:each) do
      stub_const('Puppet::Provider::TestSimpleGetFilter', Module.new)
      stub_const('Puppet::Provider::TestSimpleGetFilter::TestSimpleGetFilter', provider_class)
      allow(provider_class).to receive(:new).and_return(provider)
    end

    it { expect { described_class.register_type(definition) }.not_to raise_error }

    it 'is seen as a supported feature' do
      expect(Puppet).not_to receive(:warning).with(%r{Unknown feature detected:.*simple_test_filter})
      expect { described_class.register_type(definition) }.not_to raise_error
    end

    it 'passes through the resource title to `get`' do
      instance = type.new(name: 'bar', ensure: 'present')
      expect(provider).to receive(:get).with(anything, ['bar']).and_return([])
      instance.retrieve
    end
  end

  context 'when loading a type with unknown features' do
    let(:definition) do
      {
        name: 'test_noop_support',
        features: ['no such feature'],
        attributes: {},
      }
    end

    it 'warns about the feature' do
      expect(Puppet).to receive(:warning).with(%r{Unknown feature detected:.*no such feature})
      expect { described_class.register_type(definition) }.not_to raise_error
    end
  end

  context 'when loading a type, containing a behaviour' do
    context 'with :namevar behaviour' do
      let(:definition) do
        {
          name: 'test_behaviour',
          attributes: {
            id: {
              type: 'String',
              behavior: :namevar,
            },
          },
        }
      end

      it { expect { described_class.register_type(definition) }.not_to raise_error }
    end

    context 'with :parameter behaviour' do
      let(:definition) do
        {
          name: 'test_behaviour',
          attributes: {
            param: {
              type: 'String',
              behavior: :parameter,
            },
          },
        }
      end

      it { expect { described_class.register_type(definition) }.not_to raise_error }
    end

    context 'with :read_only behaviour' do
      let(:definition) do
        {
          name: 'test_behaviour',
          attributes: {
            param_ro: {
              type: 'String',
              behavior: :read_only,
            },
          },
        }
      end

      it { expect { described_class.register_type(definition) }.not_to raise_error }
    end

    context 'with :init_only behaviour' do
      let(:definition) do
        {
          name: 'test_behaviour',
          attributes: {
            param_ro: {
              type: 'String',
              behavior: :init_only,
            },
          },
        }
      end

      it { expect { described_class.register_type(definition) }.not_to raise_error }
    end

    context 'with :namevar behaviour' do
      let(:definition) do
        {
          name: 'test_behaviour',
          attributes: {
            source: {
              type: 'String',
              behavior: :bad,
            },
          },
        }
      end

      it { expect { described_class.register_type(definition) }.to raise_error Puppet::ResourceError, %r{^`bad` is not a valid behaviour value$} }
    end
  end

  describe '#mungify(type, value)' do
    before(:each) do
      allow(described_class).to receive(:try_mungify).with('type', 'input', 'error prefix').and_return(result)
    end
    context 'when the munge succeeds' do
      let(:result) { ['result', nil] }

      it('returns the cleaned result') { expect(described_class.mungify('type', 'input', 'error prefix')).to eq 'result' }
    end

    context 'when the munge fails' do
      let(:result) { [nil, 'some error'] }

      it('raises the error') { expect { described_class.mungify('type', 'input', 'error prefix') }.to raise_error Puppet::ResourceError, %r{\Asome error\Z} }
    end
  end

  # keep test data consistent # rubocop:disable Style/WordArray
  # run try_mungify only once to get both value, and error # rubocop:disable RSpec/InstanceVariable
  describe '#try_mungify(type, value)' do
    before(:each) do
      @value, @error = described_class.try_mungify(type, input, 'error prefix')
    end
    [
      {
        type: 'Boolean',
        transformations: [
          [true, true],
          [:true, true], # rubocop:disable Lint/BooleanSymbol
          ['true', true],
          [false, false],
          [:false, false], # rubocop:disable Lint/BooleanSymbol
          ['false', false],
        ],
        errors: ['something', 'yes', 'no', 0, 1, -1, '1', 1.1, -1.1, '1.1', '-1.1', ''],
      },
      {
        type: 'Integer',
        transformations: [
          [0, 0],
          [1, 1],
          ['1', 1],
          [-1, -1],
          ['-1', -1],
        ],
        errors: ['something', 1.1, -1.1, '1.1', '-1.1', '', :'1'],
      },
      {
        type: 'Float',
        transformations: [
          [0.0, 0.0],
          [1.5, 1.5],
          ['1.5', 1.5],
          [-1.5, -1.5],
          ['-1.5', -1.5],
        ],
        errors: ['something', '', 0, '0', 1, '1', -1, '-1', :'1.1'],
      },
      {
        type: 'Numeric',
        transformations: [
          [0, 0],
          [1, 1],
          ['1', 1],
          [-1, -1],
          ['-1', -1],
          [0.0, 0.0],
          [1.5, 1.5],
          ['1.5', 1.5],
          [-1.5, -1.5],
          ['-1.5', -1.5],
        ],
        errors: ['something', '', true, :symbol, :'1'],
      },
      {
        type: 'String',
        transformations: [
          ['', ''],
          ['1', '1'],
          [:'1', '1'],
          ['-1', '-1'],
          ['true', 'true'],
          ['false', 'false'],
          ['something', 'something'],
          [:symbol, 'symbol'],
        ],
        errors: [1.1, -1.1, 1, -1, true, false],
      },
      {
        type: 'Enum[absent, present]',
        transformations: [
          ['absent', 'absent'],
          ['absent', 'absent'],
          ['present', 'present'],
          ['present', 'present'],
        ],
        errors: ['enabled', :something, 1, 'y', 'true', ''],
      },
      {
        type: 'Pattern[/\A(0x)?[0-9a-fA-F]{8}\Z/]',
        transformations: [
          ['0xABCD1234', '0xABCD1234'],
          ['ABCD1234', 'ABCD1234'],
          [:'0xABCD1234', '0xABCD1234'],
        ],
        errors: [0xABCD1234, '1234567', 'enabled', 0, ''],
      },
      {
        type: 'Array',
        transformations: [
          [[], []],
          [[[]], [[]]],
          [['a'], ['a']],
          [['a', 1], ['a', 1]],
          [['a', 'b', 'c'], ['a', 'b', 'c']],
          [[true, 'a', 1], [true, 'a', 1]],
        ],
        errors: ['enabled', :something, 1, 'y', 'true', ''],
      },
      {
        type: 'Array[Boolean]',
        transformations: [
          [[], []],
          [[true], [true]],
          [[:true], [true]], # rubocop:disable Lint/BooleanSymbol
          [['true'], [true]],
          [[false], [false]],
          [[:false], [false]], # rubocop:disable Lint/BooleanSymbol
          [['false'], [false]],
          [[true, 'false'], [true, false]],
          [[true, true, true, 'false'], [true, true, true, false]],
        ],
        errors: [['something'], ['yes'], ['no'], [0], true, false],
      },
      {
        type: 'Array[Integer]',
        transformations: [
          [[], []],
          [[1], [1]],
          [['1'], [1]],
          [['1', 2, '3'], [1, 2, 3]],
        ],
        errors: ['enabled', :something, 1, 'y', 'true', '', [true, 'a'], [1, 'b', 3], [[]]],
      },
      {
        type: 'Array[Float]',
        transformations: [
          [[], []],
          [[1.0], [1.0]],
          [['1.0'], [1.0]],
          [['1.0', 2.0, '3.0'], [1.0, 2.0, 3.0]],
        ],
        errors: ['enabled', :something, 1, 'y', 'true', '', [true, 'a'], [1.0, 'b', 3.0], [[]]],
      },
      {
        type: 'Array[Numeric]',
        transformations: [
          [[], []],
          [[1], [1]],
          [['1'], [1]],
          [[1.0], [1.0]],
          [['1.0'], [1.0]],
          [['1.0', 2, '3'], [1.0, 2, 3]],
          [['1.0', 2.0, '3.0'], [1.0, 2.0, 3.0]],
        ],
        errors: ['enabled', :something, 1, 'y', 'true', '', [true, 'a'], [1.0, 'b', 3.0], [[]]],
      },
      {
        type: 'Array[String]',
        transformations: [
          [[], []],
          [['a'], ['a']],
          [['a', 'b', 'c'], ['a', 'b', 'c']],
        ],
        errors: ['enabled', :something, 1, 'y', 'true', '', [1], ['a', 1, 'b'], [true, 'a'], [[]]],
      },
      {
        # When requesting a Variant type, expect values to be transformed according to the rules of the constituent types.
        # Always try to up-convert, falling back to String only when necessary/possible.
        # Conversions need to be unambiguous to be valid. This should only be ever hit in pathological cases like
        # Variant[Integer, Float], or Variant[Boolean, Enum[true, false]]
        type: 'Variant[Boolean, String, Integer]',
        transformations: [
          [true, true],
          [:true, true], # rubocop:disable Lint/BooleanSymbol
          ['true', true],
          [false, false],
          [:false, false], # rubocop:disable Lint/BooleanSymbol
          ['false', false],
          [0, 0],
          [1, 1],
          ['1', 1],
          [-1, -1],
          ['-1', -1],
          ['something', 'something'],
          [:symbol, 'symbol'],
          ['1.1', '1.1'],
        ],
        errors: [1.0, [1.0], ['1']],
      },
      {
        type: 'Variant[Integer, Enum[a, "2", "3"]]',
        transformations: [
          [1, 1],
          ['a', 'a'],
        ],
        errors: ['2', '3'],
      },
      {
        type: 'Variant[Array[Variant[Integer,String]],Boolean]',
        transformations: [
          [true, true],
          [:false, false], # rubocop:disable Lint/BooleanSymbol
          [[1], [1]],
          [['1'], [1]],
          [['1', 'a'], [1, 'a']],
        ],
        errors: [
          [:something, [1.0]],
        ],
      },
    ].each do |type_test|
      context "with a #{type_test[:type]} type" do
        let(:type) { Puppet::Pops::Types::TypeParser.singleton.parse(type_test[:type]) }

        type_test[:transformations].each do |input, output|
          context "with #{input.inspect} as value" do
            let(:input) { input }

            it("transforms to #{output.inspect}") { expect(@value).to eq output }
            it('returns no error') { expect(@error).to be_nil }
          end
        end

        ([nil] + type_test[:errors]).each do |input|
          context "with #{input.inspect} as value" do
            let(:input) { input }

            it('returns no value') { expect(@value).to be_nil }
            it('returns an error') { expect(@error).to match %r{\A\s*error prefix} }
          end
        end
      end

      context "with a Optional[#{type_test[:type]}] type" do
        let(:type) { Puppet::Pops::Types::TypeParser.singleton.parse("Optional[#{type_test[:type]}]") }

        ([[nil, nil]] + type_test[:transformations]).each do |input, output|
          context "with #{input.inspect} as value" do
            let(:input) { input }

            it("transforms to #{output.inspect}") { expect(@value).to eq output }
            it("returns no error for #{input.inspect}") { expect(@error).to be_nil }
          end
        end

        type_test[:errors].each do |input|
          context "with #{input.inspect} as value" do
            let(:input) { input }

            it('returns no value') { expect(@value).to be_nil }
            it('returns an error') { expect(@error).to match %r{\A\s*error prefix} }
          end
        end
      end
    end
  end
  # rubocop:enable Style/WordArray
  # rubocop:enable RSpec/InstanceVariable
end
