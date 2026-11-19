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
      it { expect(instance.to_hiera_hash).to eq('title' => { 'attr' => 'value' }) }

      context 'when the title contains YAML special characters' do
        let(:title) { "foo:\nbar" }

        it { expect(instance.to_hiera_hash).to eq("foo:\nbar" => { 'attr' => 'value' }) }
      end

      context 'when the title is not a String' do
        let(:title) { 42 }

        it { expect(instance.to_hiera_hash).to eq('42' => { 'attr' => 'value' }) }
      end

      context 'with values that are not plain Puppet data' do
        subject(:instance) do
          described_class.new({ namevarname: title, zattr: nil, attr: :value, ensure: :present }, 'typename', [:namevarname],
                              namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                              zattr: { type: 'Optional[String]', desc: 'an unset parameter' },
                              attr: { type: 'String', desc: 'a string parameter' },
                              ensure: { type: 'Enum[present, absent]', desc: 'whether it exists' })
        end

        it 'converts them, leaves out unset ones and puts ensure first' do
          expect(instance.to_hiera_hash).to eq('title' => { 'ensure' => 'present', 'attr' => 'value' })
          expect(instance.to_hiera_hash['title'].keys).to eq %w[ensure attr]
        end
      end

      context 'with Sensitive values' do
        subject(:instance) do
          described_class.new(
            { namevarname: title, attr: 'value', secret: sensitive.new('a'), list: ['b', sensitive.new('c')], map: { 'k' => sensitive.new('d') }, variant: 42, flagged: 'e' },
            'typename', [:namevarname],
            namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
            attr: { type: 'String', desc: 'a string parameter' },
            secret: { type: 'Sensitive[String]', desc: 'a sensitive parameter' },
            list: { type: 'Array[Variant[String, Sensitive[String]]]', desc: 'a list with a sensitive value' },
            map: { type: 'Hash[String, Sensitive[String]]', desc: 'a hash with a sensitive value' },
            variant: { type: 'Variant[Array[Sensitive[String]], Integer]', desc: 'a parameter that may hold sensitive values' },
            flagged: { type: 'String', sensitive: true, desc: 'a string parameter flagged as sensitive' }
          )
        end

        let(:sensitive) { Puppet::Pops::Types::PSensitiveType::Sensitive }

        it 'leaves out the attributes whose value contains one, and those flagged as sensitive' do
          expect(instance.to_hiera_hash).to eq('title' => { 'attr' => 'value', 'variant' => 42 })
        end
      end

      context 'with hidden rsapi_custom_insync_trigger property' do
        subject(:instance) do
          described_class.new({ namevarname: title, rsapi_custom_insync_trigger: true }, 'typename', [:namevarname],
                              namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                              rsapi_custom_insync_trigger: { type: 'Boolean', desc: 'Hidden property' })
        end

        it 'doesn\'t output the hidden property' do
          expect(instance.to_hiera_hash).to eq('title' => {})
        end
      end

      context 'with several resources, as `--to_yaml` merges them' do
        let(:other) do
          described_class.new({ namevarname: 'other', attr: 'value2', attr_ro: 'fixed2' }, 'typename', [:namevarname],
                              namevarname: { type: 'String', behaviour: :namevar, desc: 'the title' },
                              attr: { type: 'String', desc: 'a string parameter' },
                              attr_ro: { type: 'String', desc: 'a string readonly', behaviour: :read_only })
        end

        it 'produces one YAML hash of all resources' do
          data = [instance, other].map { |r| r.prune_parameters(parameters_to_include: []).to_hiera_hash }.inject(:merge!)
          expect(YAML.dump('typename' => data)).to eq "---\ntypename:\n  title:\n    attr: value\n  other:\n    attr: value2\n"
        end
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
      it('compares to a string', :j17_exclude) { expect('string' <=> value).to eq 1 }
      it { expect(value <=> described_class[b: 'b', c: 'c']).to eq 0 }
      it { expect(value <=> described_class[d: 'd']).to eq(-1) }
      it { expect(value <=> described_class[a: 'a']).to eq 1 }
      it { expect(value <=> described_class[b: 'a', c: 'c']).to eq 1 }
    end
  end
end
