require 'spec_helper'

RSpec.describe Puppet::ResourceApi::DataTypeHandling do
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

  describe '#mungify(type, value, unpack_strings = false)' do
    context 'when called from `puppet resource`' do
      before(:each) do
        allow(described_class).to receive(:try_mungify).with('type', 'input', 'error prefix').and_return(result)
        allow(described_class).to receive(:validate)
      end

      let(:caller_is_resource_app) { true }

      context 'when the munge succeeds' do
        let(:result) { ['result', nil] }

        it('returns the cleaned result') { expect(described_class.mungify('type', 'input', 'error prefix', caller_is_resource_app)).to eq 'result' }
        it('validates the cleaned result') do
          described_class.mungify('type', 'input', 'error prefix', caller_is_resource_app)
          expect(described_class).to have_received(:validate).with('type', 'result', 'error prefix').once
        end
      end

      context 'when the munge fails' do
        let(:result) { [nil, 'some error'] }

        it('raises the error') { expect { described_class.mungify('type', 'input', 'error prefix', caller_is_resource_app) }.to raise_error Puppet::ResourceError, %r{\Asome error\Z} }
      end
    end

    context 'when called from something else' do
      before(:each) do
        allow(described_class).to receive(:try_mungify).never
        allow(described_class).to receive(:validate)
      end

      let(:caller_is_resource_app) { false }

      it('returns the value') { expect(described_class.mungify('type', 'input', 'error prefix', caller_is_resource_app)).to eq 'input' }
      it('validates the value') do
        described_class.mungify('type', 'input', 'error prefix', caller_is_resource_app)
        expect(described_class).to have_received(:validate).with('type', 'input', 'error prefix')
      end
    end
  end

  # keep test data consistent # rubocop:disable Style/WordArray
  # run try_mungify only once to get both value, and error # rubocop:disable RSpec/InstanceVariable
  describe '#try_validate(type, value)' do
    let(:error_msg) do
      pops_type = Puppet::Pops::Types::TypeParser.singleton.parse(type)
      described_class.try_validate(pops_type, value, 'error prefix')
    end

    [
      {
        type: 'String',
        valid: ['a', 'true'],
        invalid: [1, true],
      },
      {
        type: 'Integer',
        valid: [1, -1, 0],
        invalid: ['a', :a, 'true', 1.0],
      },
    ].each do |testcase|
      context "when validating '#{testcase[:type]}" do
        let(:type) { testcase[:type] }

        testcase[:valid].each do |valid_value|
          context "when validating #{valid_value.inspect}" do
            let(:value) { valid_value }

            it { expect(error_msg).to be nil }
          end
        end
        testcase[:invalid].each do |invalid_value|
          context "when validating #{invalid_value.inspect}" do
            let(:value) { invalid_value }

            it { expect(error_msg).to match %r{^error prefix } }
          end
        end
      end
    end
  end

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

  describe '#ambiguous_error_msg(error_msg_prefix, value, type)' do
    context 'with a Integer type' do
      context 'with a string value' do
        let(:type) { Puppet::Pops::Types::TypeParser.singleton.parse('Integer') }
        let(:value) { 'a' }
        let(:error_msg_prefix) { 'prefix' }
        let(:result) { 'prefix "a" is not unabiguously convertable to Integer' }

        it('outputs error message') do
          expect(described_class.ambiguous_error_msg(error_msg_prefix, value, type)).to eq result
        end
      end
    end
  end

  describe '#boolean_munge(value)' do
    context 'when the munge succeeds' do
      [
        {
          value: 'true',
          result: true,
        },
        {
          value: :true, # rubocop:disable Lint/BooleanSymbol
          result: true,
        },
        {
          value: true,
          result: true,
        },
        {
          value: 'false',
          result: false,
        },
        {
          value: :false, # rubocop:disable Lint/BooleanSymbol
          result: false,
        },
        {
          value: false,
          result: false,
        },
      ].each do |munge_test|
        context "with a #{munge_test[:value].class} value" do
          let(:input) { munge_test[:value] }
          let(:result) { munge_test[:result] }

          it("transforms to #{munge_test[:result]}") do
            expect(described_class.boolean_munge(input)).to eq result
          end
        end
      end
    end
  end
  # rubocop:enable Style/WordArray
  # rubocop:enable RSpec/InstanceVariable
end
