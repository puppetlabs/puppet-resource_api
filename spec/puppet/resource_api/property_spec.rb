# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::ResourceApi::Property do
  subject(:property) do
    described_class.new(type_name, data_type, attribute_name, resource_hash, referrable_type)
  end

  let(:type_name) { 'test_name' }
  let(:attribute_name) { 'some_property' }
  let(:data_type) { Puppet::Pops::Types::PStringType.new(nil) }
  let(:resource) { instance_double('resource') }
  let(:resource_hash) { { resource: resource } }
  let(:referrable_type) { Puppet::ResourceApi.register_type(name: 'minimal', attributes: {}) }
  let(:context) { instance_double('Puppet::ResourceApi::PuppetContext') }

  describe '#new(type_name, data_type, attribute_name, resource_hash, referrable_type)' do
    it { expect { described_class.new(nil) }.to raise_error ArgumentError, /wrong number of arguments/ }
    it { expect { described_class.new(type_name, data_type, attribute_name, resource_hash, referrable_type) }.not_to raise_error }
  end

  describe 'the special :ensure behaviour' do
    let(:ensure_property_class) do
      Class.new(described_class) do
        define_method(:initialize) do
          super('test_name',
            Puppet::Pops::Types::PEnumType.new(%w[absent present]),
            :ensure,
            { resource: {} },
            Puppet::ResourceApi.register_type(name: 'minimal', attributes: {}))
        end
      end
    end
    let(:ensure_property) { ensure_property_class.new }

    before do
      allow(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .with(Puppet::Pops::Types::PEnumType.new(%w[absent present]), 'present', 'test_name.ensure', false)
        .and_return('present')

      ensure_property.should = 'present'
    end

    it 'has a #insync? method' do
      expect(ensure_property.public_methods(false)).to include(:insync?)
    end

    describe '#insync?' do
      it 'compares using symbols' do
        expect(ensure_property.insync?(:present)).to eq(true)
      end
    end

    context "when handling 'present' string" do
      it { expect(ensure_property.should).to eq :present }
      it { expect(ensure_property.rs_value).to eq 'present' }
      it { expect(ensure_property.value).to eq :present }
    end
  end

  describe 'custom_insync handling' do
    subject(:custom_insync_property) { custom_insync_property_class.new }

    let(:referrable_type_custom_insync) { Puppet::ResourceApi.register_type(name: type_name, attributes: {}, features: ['custom_insync']) }
    let(:custom_insync_attribute_name) { :case_sensitive_string }
    let(:test_provider_with_insync) { instance_double('provider_with_insync') }
    let(:test_provider_without_insync) { instance_double('provider_without_insync') }
    let(:custom_insync_property_class) do
      # This awkward handling is to enable us to reference the referrable type in expectations
      passable_type_name = type_name
      passable_data_type = data_type
      passable_custom_insync_attribute_name = custom_insync_attribute_name
      passable_resource_hash = resource_hash
      passable_referrable_type_custom_insync = referrable_type_custom_insync
      Class.new(described_class) do
        define_method(:initialize) do
          super(passable_type_name,
            passable_data_type,
            passable_custom_insync_attribute_name,
            passable_resource_hash,
            passable_referrable_type_custom_insync
          )
        end
      end
    end

    context 'when the custom insync feature flag is not specified in the type' do
      before do
        property.should = 'foo'
      end

      it 'does not add custom insync handling' do
        expect(resource).not_to receive(:rsapi_canonicalized_target_state)
        expect(resource).not_to receive(:rsapi_current_state)
        expect(resource).not_to receive(:rsapi_title)
        expect(property.insync?('foo')).to be true
      end
    end

    context 'when the custom insync feature flag is specified in the type' do
      before do
        allow(resource).to receive(:rsapi_canonicalized_target_state)
        allow(resource).to receive(:rsapi_current_state)
        allow(resource).to receive(:rsapi_title)
        allow(referrable_type_custom_insync).to receive(:context).and_return(context)
      end

      context 'when calling insync?' do
        before do
          custom_insync_property.should = 'foo'
        end

        context 'when insync? is not defined in the provider' do
          it 'raises an error' do
            allow(referrable_type_custom_insync).to receive(:my_provider).and_return(test_provider_without_insync)
            expect(referrable_type_custom_insync).to receive(:my_provider)
            expect { custom_insync_property.insync?('Foo') }.to raise_error Puppet::DevError, /No insync\? method defined in the provider/
          end
        end

        context 'when insync? is defined in the provider' do
          before do
            allow(referrable_type_custom_insync).to receive(:my_provider).and_return(test_provider_with_insync)
          end

          context 'when custom insync from the provider returns nil' do
            it 'relies on the comparison in Puppet::Property.insync? if the attribute name is not ensure' do
              allow(test_provider_with_insync).to receive(:insync?).and_return(nil)
              expect(custom_insync_property.insync?('Foo')).to be false
            end

            context 'when the property is ensure' do
              let(:ensure_property_class) do
                Class.new(described_class) do
                  define_method(:initialize) do
                    super('test_name',
                      Puppet::Pops::Types::PEnumType.new(%w[absent present]),
                      :ensure,
                      { resource: {} },
                      Puppet::ResourceApi.register_type(name: 'minimal', attributes: {}))
                  end
                end
              end
              let(:ensure_property) { ensure_property_class.new }

              before do
                allow(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
                  .with(Puppet::Pops::Types::PEnumType.new(%w[absent present]), 'present', 'test_name.ensure', false)
                  .and_return('present')

                ensure_property.should = 'present'
              end

              it 'compares using symbols' do
                expect(ensure_property.insync?(:present)).to eq(true)
              end
            end
          end

          context 'when custom insync from the provider returns a boolean for the result' do
            it 'returns true if the result was true' do
              allow(test_provider_with_insync).to receive(:insync?).and_return(true)
              expect(test_provider_with_insync).to receive(:insync?)
              expect(custom_insync_property.insync?('Foo')).to be true
            end

            it 'returns false if result was false' do
              allow(test_provider_with_insync).to receive(:insync?).and_return(false)
              expect(test_provider_with_insync).to receive(:insync?)
              expect(custom_insync_property.insync?('Foo')).to be false
            end
          end

          context 'when custom insync from the provider returns a string for the result' do
            it 'raises an explanatory DevError' do
              allow(test_provider_with_insync).to receive(:insync?).and_return('true')
              expect(test_provider_with_insync).to receive(:insync?)
              expect { custom_insync_property.insync?('foo') }.to raise_error(Puppet::DevError, %r{returned a String with a value of "true" instead of true/false})
            end
          end

          context 'when custom insync from the provider returns a symbol for the result' do
            it 'raises an explanatory DevError' do
              allow(test_provider_with_insync).to receive(:insync?).and_return(:true) # rubocop:disable Lint/BooleanSymbol
              expect(test_provider_with_insync).to receive(:insync?)
              expect { custom_insync_property.insync?('foo') }.to raise_error(Puppet::DevError, %r{returned a Symbol with a value of :true instead of true/false})
            end
          end

          context 'when insync? returned an unexpected result class' do
            it 'raises an explanatory DevError' do
              allow(test_provider_with_insync).to receive(:insync?).and_return(foo: 1)
              expect(test_provider_with_insync).to receive(:insync?)
              expect { custom_insync_property.insync?('foo') }.to raise_error(Puppet::DevError, %r{returned a Hash with a value of \{:foo=>1\} instead of true/false})
            end
          end
        end
      end

      context 'when calling change_to_s' do
        before do
          allow(resource).to receive(:rsapi_canonicalized_target_state)
          allow(resource).to receive(:rsapi_current_state)
          allow(resource).to receive(:rsapi_title)
          allow(referrable_type_custom_insync).to receive(:context).and_return(context)
          allow(referrable_type_custom_insync).to receive(:my_provider).and_return(test_provider_with_insync)
        end

        context 'when the property is not rsapi_custom_insync_trigger' do
          before do
            custom_insync_property.should = 'foo'
          end

          context 'when insync? returns nil for the result' do
            it 'relies on Puppet::Property.change_to_s for change reporting' do
              allow(test_provider_with_insync).to receive(:insync?).and_return([nil, 'custom change message'])
              expect(test_provider_with_insync).to receive(:insync?)
              expect(custom_insync_property.insync?('Foo')).to be(false)
              expect(custom_insync_property.change_to_s('Foo', 'foo')).to match(/changed 'Foo' to 'foo'/)
            end
          end

          context 'when insync? returns a change message' do
            context 'when the message is empty' do
              it 'relies on Puppet::Property.change_to_s for change reporting' do
                allow(test_provider_with_insync).to receive(:insync?).and_return([false, ''])
                expect(test_provider_with_insync).to receive(:insync?)
                expect(custom_insync_property.insync?('Foo')).to be(false)
                expect(custom_insync_property.change_to_s('Foo', 'foo')).to match(/changed 'Foo' to 'foo'/)
              end
            end

            context 'when the result is nil' do
              it 'relies on Puppet::Property.change_to_s for change reporting' do
                allow(test_provider_with_insync).to receive(:insync?).and_return(nil)
                expect(test_provider_with_insync).to receive(:insync?)
                expect(custom_insync_property.insync?('Foo')).to be(false)
                expect(custom_insync_property.change_to_s('Foo', 'foo')).to match(/changed 'Foo' to 'foo'/)
              end
            end

            context 'when the result is not nil and the message is not empty' do
              it 'passes the message for change_to_s' do
                allow(test_provider_with_insync).to receive(:insync?).and_return([false, 'custom change log'])
                expect(test_provider_with_insync).to receive(:insync?)
                expect(custom_insync_property.insync?('Foo')).to be(false)
                expect(custom_insync_property.change_to_s('Foo', 'foo')).to match(/custom change log/)
              end
            end
          end
        end

        context 'when the property is rsapi_custom_insync_trigger' do
          let(:insync_result) { [false, 'Custom Change Notification'] }
          let(:custom_insync_attribute_name) { :rsapi_custom_insync_trigger }
          let(:data_type) { Puppet::Pops::Types::PBooleanType.new }

          before do
            custom_insync_property.should = true
          end

          it 'passes the default message for change reporting if insync? did not return a string' do
            allow(test_provider_with_insync).to receive(:insync?).and_return(false)
            expect(test_provider_with_insync).to receive(:insync?)
            custom_insync_property.insync?('Foo')
            expect(custom_insync_property.change_to_s(false, true)).to match(/Custom insync logic determined that this resource is out of sync/)
          end

          it 'passes the string returned by insync? for change reporting' do
            allow(test_provider_with_insync).to receive(:insync?).and_return(insync_result)
            expect(test_provider_with_insync).to receive(:insync?)
            custom_insync_property.insync?('Foo')
            expect(custom_insync_property.change_to_s(false, true)).to be insync_result[1]
          end
        end
      end
    end
  end

  describe 'should error handling' do
    it 'calls mungify and reports its error' do
      expect(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .and_raise Exception, 'error'

      expect { property.should = 'value' }.to raise_error Exception, 'error'

      expect(property.should).to eq nil
    end
  end

  describe 'value munging and storage' do
    before do
      allow(Puppet::ResourceApi::DataTypeHandling).to receive(:mungify)
        .with(data_type, value, 'test_name.some_property', false)
        .and_return(munged_value)

      property.should = value
    end

    context 'when handling strings' do
      let(:value) { 'value' }
      let(:munged_value) { 'munged value' }

      it { expect(property.should).to eq 'munged value' }
      it { expect(property.rs_value).to eq 'munged value' }
      it { expect(property.value).to eq 'munged value' }
    end

    context 'when handling boolean true' do
      let(:value) { true }
      let(:munged_value) { true }
      let(:data_type) { Puppet::Pops::Types::PBooleanType.new }

      it { expect(property.should).to eq :true } # rubocop:disable Lint/BooleanSymbol
      it { expect(property.rs_value).to eq true }
      it { expect(property.value).to eq :true } # rubocop:disable Lint/BooleanSymbol
    end
  end
end
