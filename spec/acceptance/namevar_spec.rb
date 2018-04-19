require 'spec_helper'
require 'open3'

RSpec.describe 'type with multiple namevars' do
  let(:common_args) { '--verbose --trace --modulepath spec/fixtures' }

  describe 'using `puppet resource`' do
    it 'is returns the values correctly' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} multiple_namevar")
      expect(stdout_str.strip).to match %r{^multiple_namevar}
      expect(status).to eq 0
    end
    it 'is returns the required resource correctly' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} multiple_namevar yum")
      expect(stdout_str.strip).to match %r{^multiple_namevar \{ \'yum\'}
      expect(stdout_str.strip).to match %r{ensure => \'present\'}
      expect(status).to eq 0
    end
    it 'does not match the first namevar' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} multiple_namevar php")
      expect(stdout_str.strip).to match %r{^multiple_namevar \{ \'php\'}
      expect(stdout_str.strip).to match %r{ensure => \'absent\'}
      expect(status).to eq 0
    end
  end
end
