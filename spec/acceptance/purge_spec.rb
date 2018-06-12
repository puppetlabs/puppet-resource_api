require 'spec_helper'
require 'tempfile'
require 'open3'

RSpec.describe 'purging' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures' }

  describe 'using `puppet apply`' do
    it 'applies a catalog successfully' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"resources { 'test_bool': purge => true }\"")
      expect(stdout_str).to match %r{Deleting 'foo'}
      expect(stdout_str).to match %r{Deleting 'bar'}
      expect(stdout_str).not_to match %r{Error:}
    end
  end
end
