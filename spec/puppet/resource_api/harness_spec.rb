require 'spec_helper'

RSpec.describe Puppet::ResourceApi::Harness do
  subject(:harness) { described_class.new(&block) }

  context 'when given an empty block' do
    let(:block) { proc {} }

    it { expect { harness }.to raise_error Puppet::DevError, %r{provider requires a get\(\) method} }
  end

  context 'when given a block defining a `get` method' do
    let(:block) do
      proc {
        def get
          'get called'
        end
      }
    end

    it { expect { harness }.to raise_error Puppet::DevError, %r{provider requires a set\(\) method} }
  end

  context 'when given a block defining a `get`, and a `set` method' do
    let(:block) do
      proc {
        def get
          'get called'
        end

        def set
          'set called'
        end
      }
    end

    it { expect { harness }.not_to raise_error }
    it('can execute the get method') { expect(harness.get).to eq 'get called' }
    it('can execute the set method') { expect(harness.set).to eq 'set called' }
    it('detects no `canonicalize` method') { expect(harness.canonicalize?).to be_falsey }
  end

  context 'when given a block defining a `get`, a `set`, and a `canonicalize` method' do
    let(:block) do
      proc {
        def get
          'get called'
        end

        def set
          'set called'
        end

        def canonicalize
          'canonicalize called'
        end
      }
    end

    it { expect { harness }.not_to raise_error }
    it('can execute the get method') { expect(harness.get).to eq 'get called' }
    it('can execute the set method') { expect(harness.set).to eq 'set called' }
    it('detects the `canonicalize` method') { expect(harness.canonicalize?).to be_truthy }
    it('can execute the canonicalize method') { expect(harness.canonicalize).to eq 'canonicalize called' }
  end
end
