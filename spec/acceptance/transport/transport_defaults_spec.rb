# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'open3'

RSpec.describe 'a transport' do
  let(:common_args) { '--verbose --trace --debug --strict=error --modulepath spec/fixtures' }

  before(:all) do
    FileUtils.mkdir_p(File.expand_path('~/.puppetlabs/opt/puppet/cache/devices/the_node/state'))
  end

  describe 'using `puppet device`' do
    let(:common_args) { "#{super()} --target the_node" }
    let(:device_conf) { Tempfile.new('device.conf') }
    let(:device_conf_content) do
      <<~DEVICE_CONF
        [the_node]
        type test_device_default
        url  file://#{device_credentials.path}
      DEVICE_CONF
    end
    let(:device_credentials) { Tempfile.new('credentials.txt') }

    def is_device_apply_supported?
      Gem::Version.new(Puppet::PUPPETVERSION) >= Gem::Version.new('5.3.6') && Gem::Version.new(Puppet::PUPPETVERSION) != Gem::Version.new('5.4.0')
    end

    before(:each) do
      skip "No device --apply in puppet before v5.3.6 nor in v5.4.0 (v#{Puppet::PUPPETVERSION} is installed)" unless is_device_apply_supported?
      device_conf.write(device_conf_content)
      device_conf.close

      device_credentials.write(device_credentials_content)
      device_credentials.close
    end

    after(:each) do
      device_conf.unlink
      device_credentials.unlink
    end

    context 'when all values are supplied' do
      let(:device_credentials_content) do
        <<~DEVICE_CREDS
          {
            username: foo
            default_string: other
            optional_default: bar
            array_default: [z]
          }
        DEVICE_CREDS
      end

      it 'does not use default values' do
        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(status.exitstatus).to eq 0
          expect(stdout_str).not_to match(/Value type mismatch/)
          expect(stdout_str).not_to match(/Error/)

          expect(stdout_str).to match(/transport connection_info:/)
          expect(stdout_str).to match(/:username=>"foo"/)
          expect(stdout_str).to match(/:default_string=>"other"/)
          expect(stdout_str).to match(/:optional_default=>"bar"/)
          expect(stdout_str).to match(/:array_default=>\["z"\]/)
        end
      end
    end

    context 'when no values supplied for parameters with defaults' do
      let(:device_credentials_content) do
        <<~DEVICE_CREDS
          {
            username: foo
          }
        DEVICE_CREDS
      end

      it 'uses the defaults specified' do
        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(stdout_str).not_to match(/Value type mismatch/)
          expect(stdout_str).not_to match(/Error/)

          expect(stdout_str).to match(/Debug: test_device_default: Using default value for attribute: default_string, value: "default_value"/)
          expect(stdout_str).to match(/Debug: test_device_default: Using default value for attribute: optional_default, value: "another_default_value"/)
          expect(stdout_str).to match(/Debug: test_device_default: Using default value for attribute: array_default, value: \["a", "b"\]/)
          expect(stdout_str).to match(/transport connection_info:/)
          expect(stdout_str).to match(/:username=>"foo"/)
          expect(stdout_str).to match(/:default_string=>"default_value"/)
          expect(stdout_str).to match(/:optional_default=>"another_default_value"/)
          expect(stdout_str).to match(/:array_default=>\["a", "b"\]/)

          expect(status.exitstatus).to eq 0
        end
      end
    end
  end
end
