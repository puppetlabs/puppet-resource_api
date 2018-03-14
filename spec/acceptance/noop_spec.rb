require 'spec_helper'

require 'open3'
require 'tempfile'

RSpec.describe 'exercising noop' do
  let(:common_args) { '--verbose --trace --modulepath spec/fixtures' }

  describe 'using `puppet resource`' do
    it 'is setup correctly' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} test_noop_support")
      expect(stdout_str.strip).to match %r{^test_noop_support}
      expect(status).to eq 0
    end

    it 'executes a change' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} test_noop_support foo ensure=absent")
      expect(stdout_str.strip).to match %r{noop: false}
      expect(status).to eq 0
    end

    it 'respects --noop' do
      pending 'puppet does not call flush() to trigger execution'
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} --noop test_noop_support foo ensure=absent")
      expect(stdout_str.strip).to match %r{noop: true}
      expect(status).to eq 0
    end
  end
end
