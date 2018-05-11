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
    it 'returns the required resource correctly' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} multiple_namevar php-yum package=php manager=yum")
      expect(stdout_str.strip).to match %r{^multiple_namevar \{ \'php-yum\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'present\'}
      expect(stdout_str.strip).to match %r{package\s*=> \'php\'}
      expect(stdout_str.strip).to match %r{manager\s*=> \'yum\'}
      expect(status).to eq 0
    end
    it 'returns the match if first namevar is used as title and other namevars are present' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} multiple_namevar php manager=gem")
      expect(stdout_str.strip).to match %r{^multiple_namevar \{ \'php\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'present\'}
      expect(status).to eq 0
    end
    it 'returns the match if title matches a namevar value' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} multiple_namevar php")
      expect(stdout_str.strip).to match %r{^multiple_namevar \{ \'php\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'present\'}
      expect(status).to eq 0
    end
    it 'properly identifies an absent resource if all namevars are provided' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} multiple_namevar php manager=wibble")
      expect(stdout_str.strip).to match %r{^multiple_namevar \{ \'php\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'absent\'}
      expect(status).to eq 0
    end
    it 'properly identifies an absent resource if only the title is provided' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} multiple_namevar wibble")
      expect(stdout_str.strip).to match %r{^multiple_namevar \{ \'wibble\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'absent\'}
      expect(status).to eq 0
    end
    it 'will remove an existing resource' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} multiple_namevar php manager=gem ensure=absent")
      expect(stdout_str.strip).to match %r{^multiple_namevar \{ \'php\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'absent\'}
      expect(status).to eq 0
    end
    it 'will ignore the title if namevars are provided' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} multiple_namevar whatever package=php manager=gem")
      expect(stdout_str.strip).to match %r{^multiple_namevar \{ \'whatever\'}
      expect(stdout_str.strip).to match %r{package\s*=> \'php\'}
      expect(stdout_str.strip).to match %r{manager\s*=> \'gem\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'present\'}
      expect(status).to eq 0
    end
  end
end
