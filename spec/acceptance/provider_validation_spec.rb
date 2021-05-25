# frozen_string_literal: true

require 'spec_helper'

require 'open3'
require 'tempfile'

RSpec.describe 'a provider that returns data that does not match the type schema' do
  let(:common_args) { '--verbose --trace --debug --modulepath spec/fixtures' }
  let(:message) { 'Provider returned data that does not match the Type Schema for `provider_validation' }

  [['warning', 'Warning:', 0], ['error', 'Error: Could not run:', 1], ['off', 'Debug:', 0]].each do |strict_value, prefix_value, exit_status|
    describe "when strict is set to #{strict_value}" do
      let(:common_args) { super() + " --strict=#{strict_value}" }
      let(:prefix) { prefix_value }

      it 'is raises the error in the expected manner' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} provider_validation")
        expect(stdout_str.strip).not_to match %r{#{prefix} #{message}\[a\]`}
        expect(stdout_str.strip).to match %r{#{prefix} #{message}\[b\]`\n\s*Value type mismatch:\n\s*\* string: 1}
        if strict_value != 'error'
          expect(stdout_str.strip).to match %r{#{prefix} #{message}\[c\]`\n\s*Value type mismatch:\n\s*\* boolean: true}
          expect(stdout_str.strip).to match %r{#{prefix} #{message}\[d\]`\n\s*Value type mismatch:\n\s*\* integer: one}
          expect(stdout_str.strip).to match %r{#{prefix} #{message}\[e\]`\n\s*Value type mismatch:\n\s*\* float: false}
          expect(stdout_str.strip).to match %r{#{prefix} #{message}\[f\]`\n\s*Value type mismatch:\n\s*\* variant_pattern: 0xABABABABAB}
          expect(stdout_str.strip).to match %r{#{prefix} #{message}\[g\]`\n\s*Value type mismatch:\n\s*\* url: meep}
          expect(stdout_str.strip).to match %r{#{prefix} #{message}\[h\]`\n\s*Value type mismatch:\n\s*\* optional_string: 11}
          expect(stdout_str.strip).to match %r{#{prefix} #{message}\[i\]`\n\s*Value type mismatch:\n\s*\* optional_int: omega}
          expect(stdout_str.strip).to match %r{#{prefix} #{message}\[j\]`\n\s*Unknown attribute:\n\s*\* wibble}
        end
        expect(status.exitstatus).to eq exit_status
      end
    end
  end
end
