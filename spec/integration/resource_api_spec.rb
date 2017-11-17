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
          },
          ensure: {
            type: 'String',
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
      let(:instance) { type.new(name: 'somename', ensure: 'something') }

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
