# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'a provider using arrays' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures' }

  describe 'using `puppet apply`' do
    it 'applies a catalog successfully' do
      # rubocop:disable Layout/LineLength
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_array { foo: some_array => [a, c, b], variant_array => 'not_an_array', array_of_arrays => [[a, b, c], [d, e, f]], array_from_hell => [a, [b, c], d] }\"")
      expect(stdout_str).to match(/Updating 'foo' with \{:name=>"foo", :some_array=>\["a", "c", "b"\], :variant_array=>"not_an_array", :array_of_arrays=>\[\["a", "b", "c"\], \["d", "e", "f"\]\], :array_from_hell=>\["a", \["b", "c"\], "d"\], :ensure=>"present"\}/)
      expect(stdout_str).not_to match(/Error:/)
      # rubocop:enable Layout/LineLength
    end
  end
end
