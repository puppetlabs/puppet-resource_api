require 'spec_helper'

require 'open3'
require 'tempfile'

RSpec.describe 'validation' do
  let(:common_args) { '--verbose --trace --modulepath spec/fixtures' }

  describe 'using `puppet resource`' do
    it 'allows listing' do
      output, status = Open3.capture2e("puppet resource #{common_args} test_validation")
      expect(output.strip).to match %r{^test_validation}
      expect(status).to eq 0
    end

    it 'allows listing a present instance' do
      output, status = Open3.capture2e("puppet resource #{common_args} test_validation foo")
      expect(output.strip).to match %r{^test_validation}
      expect(status).to eq 0
    end

    it 'allows listing an absent instance' do
      output, status = Open3.capture2e("puppet resource #{common_args} test_validation nope")
      expect(output.strip).to match %r{^test_validation}
      expect(status).to eq 0
    end

    it 'allows removing' do
      output, status = Open3.capture2e("puppet resource #{common_args} test_validation foo ensure=absent")
      expect(output.strip).to match %r{^test_validation}
      expect(output.strip).to match %r{Test_validation\[foo\]/ensure: undefined 'ensure' from 'present'}
      expect(status).to eq 0
    end

    it 'allows removing an absent instance' do
      output, status = Open3.capture2e("puppet resource #{common_args} test_validation nope ensure=absent")
      expect(output.strip).to match %r{^test_validation}
      expect(status).to eq 0
    end
  end

  describe 'using `puppet apply`' do
    it 'allows managing' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e 'test_validation{ foo: }'")
      expect(output.strip).not_to match %r{test_validation}i
      expect(output.strip).not_to match %r{warn|error}
      expect(status).to eq 0
    end

    it 'allows creating' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e 'test_validation{ new: }'")
      expect(output.strip).to match %r{Test_validation\[new\]/ensure: defined 'ensure' as 'present'}
      expect(status).to eq 0
    end

    it 'allows removing' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e 'test_validation{ foo: ensure => absent }'")
      expect(output.strip).to match %r{Test_validation\[foo\]/ensure: undefined 'ensure' from 'present'}
      expect(status).to eq 0
    end

    it 'allows managing an absent instance' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e 'test_validation{ gone: ensure => absent }'")
      expect(output.strip).not_to match %r{test_validation}i
      expect(output.strip).not_to match %r{warn|error}
      expect(status).to eq 0
    end
  end
end
