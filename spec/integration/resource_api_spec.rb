require 'spec_helper'

RSpec.describe 'Resource API integrated tests:' do
  context 'when running in a Type' do
    subject(:type) { Puppet::Type.type(:integration) }

    let(:definition) do
      {
        name: 'integration',
        attributes: {
          name: {
            type: 'String',
            behaviour: :namevar,
            desc: 'the title',
          },
          string: {
            type: 'String',
            desc: 'a string attribute',
            default: 'default value',
          },
          boolean: {
            type: 'Boolean',
            desc: 'a boolean attribute',
          },
          integer: {
            type: 'Integer',
            desc: 'an integer attribute',
          },
          float: {
            type: 'Float',
            desc: 'a floating point attribute',
          },
          ensure: {
            type: 'Enum[present, absent]',
            desc: 'a ensure attribute',
          },
          variant_pattern: {
            type: 'Variant[Pattern[/\A(0x)?[0-9a-fA-F]{8}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{16}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{40}\Z/]]',
            desc: 'a pattern attribute',
          },
          url: {
            type: 'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]',
            desc: 'a hkp or http(s) url attribute',
          },
          optional_string: {
            type: 'Optional[String]',
            desc: 'a optional string attribute',
          },
          string_param: {
            type: 'String',
            desc: 'a string parameter',
            default: 'default value',
            behaviour: :parameter,
          },
          boolean_param: {
            type: 'Boolean',
            desc: 'a boolean parameter',
            behaviour: :parameter,
          },
          integer_param: {
            type: 'Integer',
            desc: 'an integer parameter',
            behaviour: :parameter,
          },
          float_param: {
            type: 'Float',
            desc: 'a floating point parameter',
            behaviour: :parameter,
          },
          ensure_param: {
            type: 'Enum[present, absent]',
            desc: 'a ensure parameter',
            behaviour: :parameter,
          },
          variant_pattern_param: {
            type: 'Variant[Pattern[/\A(0x)?[0-9a-fA-F]{8}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{16}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{40}\Z/]]',
            desc: 'a pattern parameter',
            behaviour: :parameter,
          },
          url_param: {
            type: 'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]',
            desc: 'a hkp or http(s) url parameter',
            behaviour: :parameter,
          },
          optional_string_param: {
            type: 'Optional[String]',
            desc: 'a optional string parameter',
            behaviour: :parameter,
          },
          string_ro: {
            type: 'String',
            desc: 'a string readonly',
            default: 'default value',
            behaviour: :read_only,
          },
          boolean_ro: {
            type: 'Boolean',
            desc: 'a boolean readonly',
            behaviour: :read_only,
          },
          integer_ro: {
            type: 'Integer',
            desc: 'an integer readonly',
            behaviour: :read_only,
          },
          float_ro: {
            type: 'Float',
            desc: 'a floating point readonly',
            behaviour: :read_only,
          },
          ensure_ro: {
            type: 'Enum[present, absent]',
            desc: 'a ensure readonly',
            behaviour: :read_only,
          },
          variant_pattern_ro: {
            type: 'Variant[Pattern[/\A(0x)?[0-9a-fA-F]{8}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{16}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{40}\Z/]]',
            desc: 'a pattern readonly',
            behaviour: :read_only,
          },
          url_ro: {
            type: 'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]',
            desc: 'a hkp or http(s) url readonly',
            behaviour: :read_only,
          },
          optional_string_ro: {
            type: 'Optional[String]',
            desc: 'a optional string readonly',
            behaviour: :read_only,
          },
        },
      }
    end
    let(:provider_class) do
      # bring setter into scope for class
      s = setter
      Class.new do
        def get(_context)
          []
        end

        attr_reader :last_changes
        define_method(:set) do |context, changes|
          @last_changes = changes
          s.call(context, changes)
        end
      end
    end
    let(:setter) do
      proc { |_context, _changes| }
    end

    before(:each) do
      stub_const('Puppet::Provider::Integration', Module.new)
      stub_const('Puppet::Provider::Integration::Integration', provider_class)
      Puppet::ResourceApi.register_type(definition)
    end

    context 'when setting an attribute' do
      let(:instance) do
        type.new(name: 'somename', ensure: 'present', boolean: true, integer: 15, float: 1.23,
                 variant_pattern: 0xA245EED, url: 'http://www.google.com', boolean_param: false,
                 integer_param: 99, float_param: 3.21, ensure_param: 'present',
                 variant_pattern_param: '9A2222ED', url_param:  'http://www.puppet.com')
      end

      it('flushes') { expect { instance.flush }.not_to raise_exception }

      context 'when updating encounters an error' do
        let(:setter) do
          proc do |context, _changes|
            context.updating('the update message') do
              raise StandardError, 'the error message'
            end
          end
        end

        it('doesn\'t flush') { expect { instance.flush }.to raise_exception(StandardError, %r{Execution encountered an error}) }
      end
    end
  end
end
