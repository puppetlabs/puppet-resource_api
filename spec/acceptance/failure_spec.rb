# frozen_string_literal: true

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
        expect(stdout_str).to match(/Creating 'one' with \{(?:name: |:name=>)"one", (?:failure: |:failure=>)false, (?:ensure: |:ensure=>)"present"\}/)
        expect(stdout_str).to match(/Creating 'two' with \{(?:name: |:name=>)"two", (?:failure: |:failure=>)true, (?:ensure: |:ensure=>)"present"\}/)
        expect(stdout_str).to match(/Creating: Failed.*A failure for two/)
        expect(stdout_str).to match(/Could not evaluate: Execution encountered an error/)
        expect(stdout_str).to match(/Creating 'three' with \{(?:name: |:name=>)"three", (?:failure: |:failure=>)false, (?:ensure: |:ensure=>)"present"\}/)
        expect(stdout_str).not_to match(/Creating: Failed.*A failure for three/)
        expect(stdout_str).to match(/test_failure\[three\]: Finished/)
        expect(status.exitstatus).to eq 6
      end
    end
  end
end
