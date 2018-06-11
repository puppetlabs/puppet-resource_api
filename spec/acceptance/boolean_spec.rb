require 'spec_helper'
require 'tempfile'
require 'open3'

RSpec.describe 'a provider using booleans' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures --detailed-exitcodes' }

  describe 'using `puppet apply`' do
    it 'applies a catalog with no changes' do
      stdout_str, status = Open3.capture2e("puppet apply #{common_args} -e \"test_bool { foo: test_bool => true, test_bool_param => true; bar: test_bool => false, test_bool_param => false }\"")
      expect(stdout_str).not_to match %r{Updating:}
      expect(stdout_str).not_to match %r{Error:}
      expect(status.exitstatus).to eq 0
    end
    it 'applies a catalog with bool changes' do
      stdout_str, status = Open3.capture2e("puppet apply #{common_args} -e \"test_bool { foo: test_bool => false, test_bool_param => false; bar: test_bool => true, test_bool_param => true }\"")
      expect(stdout_str).to match %r{Test_bool\[foo\]/test_bool: test_bool changed (true|'true') to 'false'}
      expect(stdout_str).to match %r{Test_bool\[bar\]/test_bool: test_bool changed (false|'false') to 'true'}
      expect(stdout_str).to match %r{Updating: Updating 'foo' with \{:name=>"foo", :test_bool=>false, :test_bool_param=>false, :ensure=>"present"\}}
      expect(stdout_str).to match %r{Updating: Updating 'bar' with \{:name=>"bar", :test_bool=>true, :test_bool_param=>true, :ensure=>"present"\}}
      expect(stdout_str).not_to match %r{Error:}
      expect(status.exitstatus).to eq 2
    end
  end
end
