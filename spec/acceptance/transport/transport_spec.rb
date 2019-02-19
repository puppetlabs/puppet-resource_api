require 'spec_helper'
require 'tempfile'
require 'open3'

RSpec.describe 'a transport' do
  let(:common_args) { '--verbose --trace --debug --strict=error --modulepath spec/fixtures' }

  before(:all) do
    FileUtils.mkdir_p(File.expand_path('~/.puppetlabs/opt/puppet/cache/devices/the_node/state'))
  end

  describe 'using `puppet device`' do
    let(:common_args) { super() + ' --target the_node' }
    let(:device_conf) { Tempfile.new('device.conf') }
    let(:device_conf_content) do
      <<DEVICE_CONF
[the_node]
type test_device_sensitive
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

    context 'when all sensitive values are valid' do
      let(:device_credentials_content) do
        <<DEVICE_CREDS
{
  username: foo
  secret_string: wibble
  optional_secret: bar
  array_secret: [meep]
  variant_secret: 21
}
DEVICE_CREDS
      end

      it 'does not throw' do
        pending('Requires Puppet with NetworkDevice.rb support for Transports')

        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, _status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(stdout_str).not_to match %r{Value type mismatch}
          # These are only matched because the test transport prints them
          # This however shows that the transport can view the raw values
          expect(stdout_str).to match %r{transport connection_info:}
          expect(stdout_str).to match %r{:username=>"foo"}
          expect(stdout_str).to match %r{:secret_string=>"wibble"}
          expect(stdout_str).to match %r{:optional_secret=>"bar"}
          expect(stdout_str).to match %r{:array_secret=>\["meep"\]}
          expect(stdout_str).to match %r{:variant_secret=>21}
        end
      end
    end

    context 'with a sensitive string value that is invalid' do
      let(:device_credentials_content) do
        <<DEVICE_CREDS
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
        pending('Requires Puppet with NetworkDevice.rb support for Transports')

        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, _status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(stdout_str).to match %r{Value type mismatch}
          expect(stdout_str).to match %r{secret_string: << redacted value >> }
          expect(stdout_str).not_to match %r{optional_secret}
          expect(stdout_str).not_to match %r{array_secret}
          expect(stdout_str).not_to match %r{variant_secret}
        end
      end
    end

    context 'with an optional sensitive string value that is invalid' do
      let(:device_credentials_content) do
        <<DEVICE_CREDS
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
        pending('Requires Puppet with NetworkDevice.rb support for Transports')

        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, _status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(stdout_str).to match %r{Value type mismatch}
          expect(stdout_str).not_to match %r{secret_string }
          expect(stdout_str).to match %r{optional_secret: << redacted value >>}
          expect(stdout_str).not_to match %r{array_secret}
          expect(stdout_str).not_to match %r{variant_secret}
        end
      end
    end

    context 'with an array of sensitive strings that is invalid' do
      let(:device_credentials_content) do
        <<DEVICE_CREDS
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
        pending('Requires Puppet with NetworkDevice.rb support for Transports')

        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, _status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(stdout_str).to match %r{Value type mismatch}
          expect(stdout_str).not_to match %r{secret_string }
          expect(stdout_str).not_to match %r{optional_secret}
          expect(stdout_str).to match %r{array_secret: << redacted value >>}
          expect(stdout_str).not_to match %r{variant_secret}
        end
      end
    end

    context 'with an variant containing a sensitive value that is invalid' do
      let(:device_credentials_content) do
        <<DEVICE_CREDS
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
        pending('Requires Puppet with NetworkDevice.rb support for Transports')

        Tempfile.create('apply_success') do |f|
          f.write 'notify { "foo": }'
          f.close

          stdout_str, _status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path}  --apply #{f.path}")
          expect(stdout_str).to match %r{Value type mismatch}
          expect(stdout_str).not_to match %r{secret_string }
          expect(stdout_str).not_to match %r{optional_secret}
          expect(stdout_str).not_to match %r{array_secret}
          expect(stdout_str).to match %r{variant_secret: << redacted value >>}
        end
      end
    end
  end
end
