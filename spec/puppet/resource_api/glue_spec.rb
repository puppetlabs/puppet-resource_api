# frozen_string_literal: true

require 'spec_helper'

# The tests in here are only a light dusting to avoid accidents,
# but for serious testing, these need to go through a full
# `puppet resource` read/write cycle to ensure that there is nothing
# funky happening with new puppet versions.
RSpec.describe 'the dirty bits' do
  describe Puppet::ResourceApi::ResourceShim do
    subject(:instance) do
      described_class.new({ namevarname: title, attr: 'value', attr_ro: 'fixed' }, 'typename', [:namevarname],
                          namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                          attr: { type: 'String', desc: 'a string parameter' },
                          attr_ro: { type: 'String', desc: 'a string readonly', behaviour: :read_only })
    end

    let(:title) { 'title' }

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

      context 'with nil values' do
        subject(:instance) do
          described_class.new({ namevarname: title, attr: nil, attr_ro: 'fixed' }, 'typename', [:namevarname],
                              namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                              attr: { type: 'String', desc: 'a string parameter' },
                              attr_ro: { type: 'String', desc: 'a string readonly', behaviour: :read_only })
        end

        it 'doesn\'t output them' do
          expect(instance.to_manifest).to eq "typename { 'title': \n# attr_ro => 'fixed', # Read Only\n}"
        end
      end

      context 'with hidden rsapi_custom_insync_trigger property' do
        subject(:instance) do
          described_class.new({ namevarname: title, rsapi_custom_insync_trigger: true }, 'typename', [:namevarname],
                              namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                              rsapi_custom_insync_trigger: { type: 'Boolean', desc: 'Hidden property' })
        end

        it 'doesn\'t output the hidden property' do
          expect(instance.to_manifest).not_to match(/rsapi_custom_insync_trigger/)
        end
      end
    end

    describe '.to_json' do
      it { expect(instance.to_json).to eq '{"title":{"attr":"value","attr_ro":"fixed"}}' }

      context 'with nil values' do
        subject(:instance) do
          described_class.new({ namevarname: title, attr: nil, attr_ro: 'fixed' }, 'typename', [:namevarname],
                              namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                              attr: { type: 'String', desc: 'a string parameter' },
                              attr_ro: { type: 'String', desc: 'a string readonly', behaviour: :read_only })
        end

        it 'doesn\'t output them' do
          expect(instance.to_json).to eq '{"title":{"attr_ro":"fixed"}}'
        end
      end

      context 'with hidden rsapi_custom_insync_trigger property' do
        subject(:instance) do
          described_class.new({ namevarname: title, rsapi_custom_insync_trigger: true }, 'typename', [:namevarname],
                              namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                              rsapi_custom_insync_trigger: { type: 'Boolean', desc: 'Hidden property' })
        end

        it 'doesn\'t output the hidden property' do
          expect(instance.to_json).not_to match(/rsapi_custom_insync_trigger/)
        end
      end
    end

    describe '.to_hierayaml' do
      it { expect(instance.to_hierayaml).to eq "  title:\n    attr: value\n    attr_ro: fixed\n" }

      context 'when the title contains YAML special characters' do
        let(:title) { "foo:\nbar" }

        it { expect(instance.to_hierayaml).to eq "  ? |-\n    foo:\n    bar\n  : attr: value\n    attr_ro: fixed\n" }
      end

      context 'with hidden rsapi_custom_insync_trigger property' do
        subject(:instance) do
          described_class.new({ namevarname: title, rsapi_custom_insync_trigger: true }, 'typename', [:namevarname],
                              namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                              rsapi_custom_insync_trigger: { type: 'Boolean', desc: 'Hidden property' })
        end

        it 'doesn\'t output the hidden property' do
          expect(instance.to_hierayaml).not_to match(/rsapi_custom_insync_trigger/)
        end
      end
    end

    describe '.to_hiera_hash' do
      it { expect(instance.to_hiera_hash).to eq "  title:\n    attr: value\n    attr_ro: fixed\n" }

      context 'when the title contains YAML special characters' do
        let(:title) { "foo:\nbar" }

        it { expect(instance.to_hiera_hash).to eq "  ? |-\n    foo:\n    bar\n  : attr: value\n    attr_ro: fixed\n" }
      end
    end

    describe '.to_hash' do
      it { expect(instance.to_hash).to eq(namevarname: 'title', attr: 'value', attr_ro: 'fixed') }
    end
  end

  describe Puppet::ResourceApi::MonkeyHash do
    it { expect(described_class.ancestors).to include Hash }

    describe '#<=>(other)' do
      subject(:value) { described_class[b: 'b', c: 'c'] }

      it { expect(value <=> 'string').to eq(-1) }
      # Avoid this test on jruby 1.7, where it is hitting a implementation inconsistency and `'string' <=> value` returns `nil`
      it('compares to a string', j17_exclude: true) { expect('string' <=> value).to eq 1 }
      it { expect(value <=> described_class[b: 'b', c: 'c']).to eq 0 }
      it { expect(value <=> described_class[d: 'd']).to eq(-1) }
      it { expect(value <=> described_class[a: 'a']).to eq 1 }
      it { expect(value <=> described_class[b: 'a', c: 'c']).to eq 1 }
    end
  end
end
