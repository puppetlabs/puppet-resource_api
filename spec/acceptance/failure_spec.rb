require 'spec_helper'
require 'tempfile'

RSpec.describe 'a provider showing failure' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures --detailed-exitcodes' }

  describe 'using `puppet apply`' do
    let(:result) { Open3.capture2e("puppet apply #{common_args} -e \"#{manifest.delete("\n").squeeze(' ')}\"") }
    let(:stdout_str) { result[0] }
    let(:status) { result[1] }

    context 'when changes are made' do
      let(:manifest) do
        <<DOC
        test_failure {
          one:   failure=>false;
          two:   failure=>true;
          three: failure=>false;
        }
DOC
      end

      it 'applies a catalog with some failing resources' do
        expect(stdout_str).to match %r{Creating 'one' with \{:name=>"one", :failure=>false, :ensure=>"present"\}}
        expect(stdout_str).to match %r{Creating 'two' with \{:name=>"two", :failure=>true, :ensure=>"present"\}}
        expect(stdout_str).to match %r{Creating: Failed.*A failure for two}
        expect(stdout_str).to match %r{Could not evaluate: Execution encountered an error}
        expect(stdout_str).to match %r{Creating 'three' with \{:name=>"three", :failure=>false, :ensure=>"present"\}}
        expect(stdout_str).not_to match %r{Creating: Failed.*A failure for three}
        expect(stdout_str).to match %r{test_failure\[three\]: Finished}
        expect(status.exitstatus).to eq 6
      end
    end
  end
end
