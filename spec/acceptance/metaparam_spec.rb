require 'spec_helper'

require 'open3'
require 'tempfile'

RSpec.describe 'meta parameters' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures' }

  describe 'using `puppet apply`' do
    it 'are handled' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e \"include test_module::metaparam_support\"")
      expect(output.strip).not_to match %r{warn|error}i
      expect(status.exitstatus).to eq 0
    end
  end
end
