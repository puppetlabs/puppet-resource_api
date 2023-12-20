# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'open3'

RSpec.describe 'a type with optional ensure' do
  # these common_args *have* to use debug to see the messages we are matching
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures --debug' }

  describe 'using `puppet apply`' do
    it 'creates an absent resource when ensure => present is specified' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_optional_ensure { newres: ensure => present, prop => 'myprop' }\"")
      expect(stdout_str).to match(/Creating: Creating 'newres' with/)
    end

    it 'deletes an existing resource when ensure => absent is specified' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_optional_ensure { existing: ensure => absent }\"")
      expect(stdout_str).to match(/Deleting: Deleting 'existing'/)
    end

    it 'does nothing when an unknown resource is referenced with no ensure' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_optional_ensure { missing: }\"")
      expect(stdout_str).to match(/Test_optional_ensure\[missing\]: Nothing to manage: /)
      expect(stdout_str).not_to match(/Creating: /)
      expect(stdout_str).not_to match(/Updating: /)
      expect(stdout_str).not_to match(/Deleting: /)
    end

    it 'does nothing when an existing resource is referenced with no ensure and no properties' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_optional_ensure { existing: }\"")
      expect(stdout_str).to match(/Current State: \{:namevar=>"existing"/)
      expect(stdout_str).not_to match(/Creating: /)
      expect(stdout_str).not_to match(/Updating: /)
      expect(stdout_str).not_to match(/Deleting: /)
    end

    it 'updates changed properties when an existing resource is referenced with no ensure' do
      stdout_str, _status = Open3.capture2e("puppet apply #{common_args} -e \"test_optional_ensure { existing: prop => 'asdf' }\"")
      expect(stdout_str).to match(/Updating: Updating 'existing' with/)
      expect(stdout_str).not_to match(/Creating: /)
      expect(stdout_str).not_to match(/Deleting: /)
    end
  end
end
