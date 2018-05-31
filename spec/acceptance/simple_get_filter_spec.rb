require 'spec_helper'

require 'open3'
require 'tempfile'

RSpec.describe 'exercising simple_get_filter' do
  let(:common_args) { '--verbose --debug --trace --strict=error --modulepath spec/fixtures' }

  describe 'using `puppet resource`' do
    context 'when using `get` to access all resources' do
      it 'does not receive names array' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} test_simple_get_filter")

        expect(stdout_str.strip).to match %r{^test_simple_get_filter \{ 'bar'}
        expect(stdout_str.strip).to match %r{^test_simple_get_filter \{ 'foo'}
        expect(status).to eq 0
      end
    end

    context 'when using `get` to access a specific resource' do
      it 'returns resource' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} test_simple_get_filter foo")

        expect(stdout_str.strip).to match %r{test_string\s*=>\s*'default'}
        expect(status).to eq 0
      end
    end

    context 'when using `get` to remove a specific resource' do
      it 'receives names array' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} test_simple_get_filter foo ensure=absent")

        expect(stdout_str.strip).to match %r{undefined 'ensure' from 'present'}
        expect(stdout_str.strip).to match %r{test_string\s*=>\s*'foo found'}
        expect(status).to eq 0
      end
    end
  end
end
