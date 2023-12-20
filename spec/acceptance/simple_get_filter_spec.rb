# frozen_string_literal: true

require 'spec_helper'

require 'open3'
require 'tempfile'

RSpec.describe 'exercising simple_get_filter' do
  let(:common_args) { '--verbose --debug --trace --strict=error --modulepath spec/fixtures' }

  describe 'using `puppet resource`' do
    context 'when using `get` to access the initial data set' do
      it 'does not receive names array' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} test_simple_get_filter")

        expect(stdout_str.strip).to match(/^test_simple_get_filter \{ 'wibble'/)
        expect(stdout_str.strip).to match(/^test_simple_get_filter \{ 'bar'/)
        expect(status).to eq 0
      end
    end

    context 'when using `get` to access a specific resource' do
      it '`puppet resource` uses `instances` and does the filtering' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} test_simple_get_filter wibble")

        expect(stdout_str.strip).to match(/test_string\s*=>\s*'wibble default'/)
        expect(status).to eq 0
      end
    end

    context 'when using `get` to remove a specific resource' do
      it 'the `retrieve` function does the lookup' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} test_simple_get_filter foo")

        expect(stdout_str.strip).to match(/test_string\s*=>\s*'foo found'/)
        expect(status).to eq 0
      end
    end
  end
end
