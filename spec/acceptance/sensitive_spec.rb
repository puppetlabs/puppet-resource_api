# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'open3'

RSpec.describe 'sensitive data' do
  # these common_args *have* to use debug to check *all* log messages for the sensitive value
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures  --debug' }

  describe 'using `puppet apply`' do
    it 'is not exposed by notify' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"notice(Sensitive('sesitive_data'))\"")
      expect(stdout_str).to match %r{redacted}
      expect(stdout_str).not_to match %r{sesitive_data}
      expect(stdout_str).not_to match %r{warn|error}i
    end

    it 'is not exposed by a provider' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_sensitive { test_resource: secret => Sensitive('sesitive_data'), "\
        "optional_secret => Sensitive('optional sesitive_data'), array_secret => [Sensitive('array sesitive_data')] }\"")
      expect(stdout_str).to match %r{redacted}
      expect(stdout_str).not_to match %r{sesitive_data}
      expect(stdout_str).not_to match %r{warn|error}i
    end

    context 'when a sensitive value is not the top level type' do
      it 'is not exposed by a provider' do
        stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_sensitive { test_resource: secret => Sensitive('sesitive_data'), "\
          "optional_secret => Sensitive('optional sesitive_data'), variant_secret => [Sensitive('variant sesitive_data')] }\"")
        expect(stdout_str).to match %r{redacted}
        expect(stdout_str).not_to match %r{variant sesitive_data}
        expect(stdout_str).not_to match %r{warn|error}i
      end
      it 'properly validates the sensitive type value' do
        stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_sensitive { test_resource: secret => Sensitive('sesitive_data'), "\
          "optional_secret => Sensitive('optional sesitive_data'), variant_secret => [Sensitive(134679)] }\"")
        expect(stdout_str).to match %r{Sensitive\[String\]( value)?, got Sensitive\[Integer\]}
        expect(stdout_str).not_to match %r{134679}
      end
    end
  end

  describe 'using `puppet resource`' do
    it 'is not exposed in the output' do
      stdout_str, _status = Open3.capture2e("puppet resource #{common_args} test_sensitive")
      expect(stdout_str).to match %r{redacted}
      expect(stdout_str).not_to match %r{(sesitive_data|test_resource)secret}
      expect(stdout_str).not_to match %r{warn|error}i
    end
  end
end
