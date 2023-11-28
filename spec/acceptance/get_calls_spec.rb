# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'minimizing provider get calls' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures' }

  describe 'using `puppet resource` with a basic type' do
    it 'calls get 1 time' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} test_get_calls_basic")
      expect(stdout_str).to match %r{Notice: test_get_calls_basic: Provider get called 1 times}
      expect(stdout_str).not_to match %r{Notice: test_get_calls_basic: Provider get called 2 times}
      expect(status).to eq 0
    end
  end

  describe 'using `puppet apply` with a basic type' do
    it 'calls get 2 times' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_get_calls_basic { foo: } test_get_calls_basic { bar: }\"")
      expect(stdout_str).to match %r{Notice: test_get_calls_basic: Provider get called 1 times}
      expect(stdout_str).to match %r{Notice: test_get_calls_basic: Provider get called 2 times}
      expect(stdout_str).not_to match %r{Notice: test_get_calls_basic: Provider get called 3 times}
      expect(stdout_str).not_to match %r{Creating}
    end

    it 'calls get 3 times with resource purging' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_get_calls_basic { foo: } test_get_calls_basic { bar: } resources { test_get_calls_basic: purge => true }\"")
      expect(stdout_str).to match %r{Notice: test_get_calls_basic: Provider get called 1 times}
      expect(stdout_str).to match %r{Notice: test_get_calls_basic: Provider get called 2 times}
      expect(stdout_str).to match %r{Notice: test_get_calls_basic: Provider get called 3 times}
      expect(stdout_str).not_to match %r{Notice: test_get_calls_basic: Provider get called 4 times}
      expect(stdout_str).not_to match %r{Creating}
    end
  end

  describe 'using `puppet resource` with a simple_get_filter type' do
    it 'calls get 1 time' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} test_get_calls_sgf")
      expect(stdout_str).to match %r{Notice: test_get_calls_sgf: Provider get called 1 times}
      expect(stdout_str).not_to match %r{Notice: test_get_calls_sgf: Provider get called 2 times}
      expect(status.exitstatus).to be_zero
    end
  end

  describe 'using `puppet apply` with a type using simple_get_filter' do
    it 'calls get 2 times' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_get_calls_sgf { foo: } test_get_calls_sgf { bar: }\"")
      expect(stdout_str).to match %r{Notice: test_get_calls_sgf: Provider get called 1 times}
      expect(stdout_str).to match %r{Notice: test_get_calls_sgf: Provider get called 2 times}
      expect(stdout_str).not_to match %r{Notice: test_get_calls_sgf: Provider get called 3 times}
      expect(stdout_str).not_to match %r{Creating}
    end

    it 'calls get 3 times when resource purging' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_get_calls_sgf { foo: } test_get_calls_sgf { bar: } resources { test_get_calls_sgf: purge => true }\"")
      expect(stdout_str).to match %r{Notice: test_get_calls_sgf: Provider get called 1 times}
      expect(stdout_str).to match %r{Notice: test_get_calls_sgf: Provider get called 2 times}
      expect(stdout_str).to match %r{Notice: test_get_calls_sgf: Provider get called 3 times}
      expect(stdout_str).not_to match %r{Notice: test_get_calls_sgf: Provider get called 4 times}
      expect(stdout_str).not_to match %r{Creating}
    end
  end
end
