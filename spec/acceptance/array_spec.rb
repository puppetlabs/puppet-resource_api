require 'spec_helper'
require 'tempfile'

RSpec.describe 'a provider using arrays' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures' }

  describe 'using `puppet apply`' do
    it 'applies a catalog successfully' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_array { foo: some_array => [a, c, b] }\"")
      expect(stdout_str).to match %r{Updating 'foo' with \{:name=>"foo", :some_array=>\["a", "c", "b"\], :ensure=>"present"\}}
      expect(stdout_str).not_to match %r{Error:}
    end
  end
end
