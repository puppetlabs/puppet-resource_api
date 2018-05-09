require 'spec_helper'

# The tests in here are only a light dusting to avoid accidents,
# but for serious testing, these need to go through a full
# `puppet resource` read/write cycle to ensure that there is nothing
# funky happening with new puppet versions.
RSpec.describe 'the dirty bits' do
  describe Puppet::ResourceApi::TypeShim do
    subject(:instance) do
      described_class.new('title', { attr: 'value', attr_ro: 'fixed' }, 'typename', :namevarname,
                          namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                          attr: { type: 'String', desc: 'a string parameter' },
                          attr_ro: { type: 'String', desc: 'a string readonly', behaviour: :read_only })
    end

    describe '.values' do
      it { expect(instance.values).to eq(namevarname: 'title', attr: 'value', attr_ro: 'fixed') }
    end

    describe '.typename' do
      it { expect(instance.typename).to eq 'typename' }
    end

    describe '.name' do
      it { expect(instance.name).to eq 'title' }
    end

    describe '.namevar' do
      it { expect(instance.namevar).to eq :namevarname }
    end

    describe '.to_resource' do
      it { expect(instance.to_resource).to be_a Puppet::ResourceApi::ResourceShim }

      describe '.values' do
        it { expect(instance.to_resource.values).to eq(namevarname: 'title', attr: 'value', attr_ro: 'fixed') }
      end

      describe '.typename' do
        it { expect(instance.to_resource.typename).to eq 'typename' }
      end

      describe '.namevar' do
        it { expect(instance.to_resource.namevar).to eq :namevarname }
      end
    end
  end

  describe Puppet::ResourceApi::ResourceShim do
    subject(:instance) do
      described_class.new({ namevarname: 'title', attr: 'value', attr_ro: 'fixed' }, 'typename', :namevarname,
                          namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                          attr: { type: 'String', desc: 'a string parameter' },
                          attr_ro: { type: 'String', desc: 'a string readonly', behaviour: :read_only })
    end

    describe '.values' do
      it { expect(instance.values).to eq(namevarname: 'title', attr: 'value', attr_ro: 'fixed') }
    end

    describe '.typename' do
      it { expect(instance.typename).to eq 'typename' }
    end

    describe '.title' do
      it { expect(instance.title).to eq 'title' }
    end

    describe '.prune_parameters(*_args)' do
      it { expect(instance.prune_parameters).to eq instance }
    end

    describe '.to_manifest' do
      it { expect(instance.to_manifest).to eq "typename { 'title': \n  attr => 'value',\n# attr_ro => 'fixed', # Read Only\n}" }
    end

    describe '.to_hierayaml' do
      it { expect(instance.to_hierayaml).to eq "  title: \n    attr: 'value'\n    attr_ro: 'fixed'\n" }
    end
  end
end
