require 'spec_helper'

# TODO: needs some cleanup/helper to avoid this misery
module Puppet::Provider::TestCustomInsync; end
require 'puppet/provider/test_custom_insync/test_custom_insync'

RSpec.describe Puppet::Provider::TestCustomInsync::TestCustomInsync do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:name) { 'example' }
  let(:base_should_hash) { { name: 'example', ensure: 'present' } }
  let(:all_resources) do
    [
      {
        name: 'example',
        ensure: 'present',
        some_array: ['a', 'b'],
        case_sensitive_string: 'FooBar',
        case_insensitive_string: 'FooBar',
        version: '1.2.3',
      },
      {
        name: 'dependent',
        ensure: 'present',
        some_array: ['a', 'b'],
        case_sensitive_string: 'FooBar',
        case_insensitive_string: 'FooBar',
        version: '1.2.3',
      }
    ]
  end
  let(:is_hash) { all_resources.select { |hash| hash[:name] == 'example' }.first }

  describe '#get' do
    it 'processes resources' do
      expect(provider.get(context)).to eq all_resources
    end
  end

  describe 'insync?(context, name, property_name, is_hash, should_hash)' do
    subject { provider.insync?(context, name, property_name, is_hash, should_hash) }

    before(:each) do
      allow(context).to receive(:notice).with(%r{\AChecking whether #{property_name.to_s} is out of sync})
    end

    context 'when handling arrays' do
      let(:property_name) { :some_array }

      context 'when handling order independent arrays' do
        before(:each) do
          allow(context).to receive(:notice).with(%r{\AChecking an order independent array})
        end

        context 'when the actual value is an exact match' do
          let(:should_hash) { base_should_hash.merge({ some_array: ['a', 'b'], force: true }) }

          it {is_expected.to be true }
        end

        context 'when the actual value is an order insensitive match' do
          let(:should_hash) { base_should_hash.merge({ some_array: ['b', 'a'], force: true }) }

          it {is_expected.to be true }
        end

        context 'when the actual value is missing an array member' do
          let(:should_hash) { base_should_hash.merge({ some_array: ['c'], force: true }) }

          it {is_expected.to be false }
        end

        context 'when the actual value has an extra array member' do
          let(:should_hash) { base_should_hash.merge({ some_array: ['a'], force: true }) }

          it {is_expected.to be false }
        end
      end

      context 'when handling subset match arrays' do
        let(:should_hash) { base_hash.merge({ some_array: ['a', 'b'] }) }

        before(:each) do
          allow(context).to receive(:notice).with(%r{\AChecking a subset match array})
        end

        context 'when the actual value is an exact match' do
          let(:should_hash) { base_should_hash.merge({ some_array: ['a', 'b'] }) }

          it { is_expected.to be true }
        end

        context 'when the actual value is missing an array member' do
          let(:should_hash) { base_should_hash.merge({ some_array: ['c'] }) }

          it { is_expected.to eq [false, 'Adding missing members ["c"]'] }
        end

        context 'when the actual value has an extra array member' do
          let(:should_hash) { base_should_hash.merge({ some_array: ['a'] }) }

          it { is_expected.to be true }
        end
      end
    end

    context 'when handling strings' do
      context 'case sensitively' do
        let(:property_name) { :case_sensitive_string }
        let(:should_hash) { base_should_hash.merge({ case_sensitive_string: 'FooBar' })}

        it 'falls back on Puppet::Property.insync? for comparison, returning nil' do
          expect(subject).to be nil
        end
      end

      context 'case insensitively' do
        let(:property_name) { :case_insensitive_string }

        context 'when the value is an exact match' do
          let(:should_hash) { base_should_hash.merge({ case_insensitive_string: 'FooBar' })}
          it { is_expected.to be true }
        end
        context 'when the value is a downcased match' do
          let(:should_hash) { base_should_hash.merge({ case_insensitive_string: 'foobar' })}
          it { is_expected.to be true }
        end
        context 'when the value is different' do
          let(:should_hash) { base_should_hash.merge({ case_insensitive_string: 'FooBarBaz' })}
          it { is_expected.to be false }
        end
      end
    end

    context 'when handling versions' do
      let(:property_name) { :version }

      context 'exactly' do
        let(:should_hash) { base_should_hash.merge({ version: '1.2.3' })}

        it 'falls back on Puppet::Property.insync? for comparison, returning nil' do
          expect(subject).to be nil
        end
      end

      context 'with a custom version string' do
        before(:each) { allow(context).to receive(:notice).with(%r{\AChecking a custom version bound}) }

        context 'when the custom version string is invalid' do
          let(:should_hash) { base_should_hash.merge({ version: '>!& 1.2.3' }) }

          it 'raises a BadRequirementError via Gem::Requirement' do
            expect { subject }.to raise_error Gem::Requirement::BadRequirementError
          end
        end

        context 'when the custom version string condition is satisfied' do
          let(:should_hash) { base_should_hash.merge({ version: '> 1.0.0' }) }

          it { is_expected.to be true }
        end

        context 'when the custom version string condition is not satisfied' do
          let(:should_hash) { base_should_hash.merge({ version: '> 2.0.0' }) }

          it { is_expected.to eq [false, 'The actual version (1.2.3) does not meet the custom version bound (> 2.0.0); updating to a version that does'] }
        end
      end
      context 'with a minimum version bound' do
        before(:each) { allow(context).to receive(:notice).with(%r{\AChecking a min/max version}) }

        context 'when it is satisfied' do
          let(:should_hash) { base_should_hash.merge({ version: '', minimum_version: '1.0.0' }) }

          it { is_expected.to be true }
        end

        context 'when it is not satisfied' do
          let(:should_hash) { base_should_hash.merge({ version: '', minimum_version: '2.0.0' }) }

          it { is_expected.to eq [false, 'The actual version (1.2.3) does not meet the minimum version bound (2.0.0); updating to a version that does'] }
        end
      end
      context 'with a maximum version bound' do
        before(:each) { allow(context).to receive(:notice).with(%r{\AChecking a min/max version}) }

        context 'when it is satisfied' do
          let(:should_hash) { base_should_hash.merge({ version: '', maximum_version: '2.0.0' }) }

          it { is_expected.to be true }
        end

        context 'when it is not satisfied' do
          let(:should_hash) { base_should_hash.merge({ version: '', maximum_version: '1.0.0' }) }

          it { is_expected.to eq [false, 'The actual version (1.2.3) does not meet the maximum version bound (1.0.0); updating to a version that does'] }
        end
      end
      context 'with combined minimum & maximum version bounds' do
        before(:each) { allow(context).to receive(:notice).with(%r{\AChecking a min/max version}) }

        context 'when they are satisfied' do
          let(:should_hash) { base_should_hash.merge({ version: '', minimum_version: '1.0.0', maximum_version: '2.0.0' }) }

          it { is_expected.to be true }
        end

        context 'when they are not satisfied' do
          let(:should_hash) { base_should_hash.merge({ version: '', minimum_version: '2.0.0', maximum_version: '3.0.0' }) }

          it { is_expected.to eq [false, 'The actual version (1.2.3) does not meet the combined minimum (2.0.0) and maximum (3.0.0) bounds; updating to a version which does.'] }
        end
      end
    end
  end
end
