# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'open3'

RSpec.describe 'a transport' do
  let(:common_args) { '--verbose --trace --debug --strict=error --modulepath spec/fixtures' }

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    FileUtils.mkdir_p(File.expand_path('~/.puppetlabs/opt/puppet/cache/devices/the_node/state'))
  end

  describe 'using `puppet device`' do
    let(:common_args) { "#{super()} --target the_node" }
    let(:device_conf) { Tempfile.new('device.conf') }
    let(:device_conf_content) do
      <<~DEVICE_CONF
        [the_node]
        type test_device_sensitive
        url  file://#{device_credentials.path}
      DEVICE_CONF
    end
    let(:device_credentials) { Tempfile.new('credentials.txt') }

    before do
      device_conf.write(device_conf_content)
      device_conf.close

      device_credentials.write(device_credentials_content)
      device_credentials.close
    end

    after do
      device_conf.unlink
      device_credentials.unlink
    end

    context 'when all sensitive values are valid' do
      let(:device_credentials_content) do
        <<~DEVICE_CREDS
          {
            username: foo
            secret_string: wibble
            optional_secret: bar
            array_secret: [meep]
            variant_secret: 1234567890
          }
        DEVICE_CREDS
      end

      it 'does not throw' do
        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(status.exitstatus).to eq 0
          expect(stdout_str).not_to match(/Value type mismatch/)
          expect(stdout_str).not_to match(/Error/)

          expect(stdout_str).to match(/transport connection_info:/)
          expect(stdout_str).to match(/:username=>"foo"/)
          expect(stdout_str).not_to match(/wibble/)
          expect(stdout_str).not_to match(/bar/)
          expect(stdout_str).not_to match(/meep/)
          expect(stdout_str).not_to match(/1234567890/)
        end
      end
    end

    context 'with a sensitive string value that is invalid' do
      let(:device_credentials_content) do
        <<~DEVICE_CREDS
          {
            username: foo
            secret_string: 12345
            optional_secret: wibble
            array_secret: [meep]
            variant_secret: 21
          }
        DEVICE_CREDS
      end

      it 'Value type mismatch' do
        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(stdout_str).to match(/Error/)
          expect(stdout_str).to match(/Value type mismatch/)
          expect(stdout_str).to match(/secret_string: << redacted value >> /)
          expect(stdout_str).not_to match(/optional_secret/)
          expect(stdout_str).not_to match(/array_secret/)
          expect(stdout_str).not_to match(/variant_secret/)

          expect(status.exitstatus).to eq 1
        end
      end
    end

    context 'with an optional sensitive string value that is invalid' do
      let(:device_credentials_content) do
        <<~DEVICE_CREDS
          {
            username: foo
            secret_string: wibble
            optional_secret: 12345
            array_secret: [meep]
            variant_secret: 21
          }
        DEVICE_CREDS
      end

      it 'Value type mismatch' do
        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(stdout_str).to match(/Error/)
          expect(stdout_str).to match(/Value type mismatch/)
          expect(stdout_str).not_to match(/secret_string /)
          expect(stdout_str).to match(/optional_secret: << redacted value >>/)
          expect(stdout_str).not_to match(/array_secret/)
          expect(stdout_str).not_to match(/variant_secret/)

          expect(status.exitstatus).to eq 1
        end
      end
    end

    context 'with an array of sensitive strings that is invalid' do
      let(:device_credentials_content) do
        <<~DEVICE_CREDS
          {
            username: foo
            secret_string: wibble
            optional_secret: bar
            array_secret: [17]
            variant_secret: 21
          }
        DEVICE_CREDS
      end

      it 'Value type mismatch' do
        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(stdout_str).to match(/Error/)
          expect(stdout_str).to match(/Value type mismatch/)
          expect(stdout_str).not_to match(/secret_string /)
          expect(stdout_str).not_to match(/optional_secret/)
          expect(stdout_str).to match(/array_secret: << redacted value >>/)
          expect(stdout_str).not_to match(/variant_secret/)

          expect(status.exitstatus).to eq 1
        end
      end
    end

    context 'with an variant containing a sensitive value that is invalid' do
      let(:device_credentials_content) do
        <<~DEVICE_CREDS
          {
            username: foo
            secret_string: wibble
            optional_secret: bar
            array_secret: [meep]
            variant_secret: wobble
          }
        DEVICE_CREDS
      end

      it 'Value type mismatch' do
        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(stdout_str).to match(/Error/)
          expect(stdout_str).to match(/Value type mismatch/)
          expect(stdout_str).not_to match(/secret_string /)
          expect(stdout_str).not_to match(/optional_secret/)
          expect(stdout_str).not_to match(/array_secret/)
          expect(stdout_str).to match(/variant_secret: << redacted value >>/)

          expect(status.exitstatus).to eq 1
        end
      end
    end
  end
end
