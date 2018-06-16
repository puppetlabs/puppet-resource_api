require 'spec_helper'
require 'tempfile'

RSpec.describe 'exercising a device provider' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures' }
  let(:default_type_values) do
    'string="meep" boolean=true integer=15 float=1.23 ensure=present variant_pattern=AE321EEF '\
                                'url="http://www.puppet.com" boolean_param=false integer_param=99 float_param=3.21 '\
                                'ensure_param=present variant_pattern_param=0xAE321EEF url_param="https://www.google.com"'
  end

  before(:each) { skip 'No device --apply in the puppet gems yet' if ENV['PUPPET_GEM_VERSION'] }

  describe 'using `puppet resource`' do
    it 'manages resources on the target system' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} device_provider foo ensure=present #{default_type_values}")
      expect(stdout_str).to match %r{Notice: /Device_provider\[foo\]/ensure: defined 'ensure' as 'present'}
      expect(status).to eq 0
    end

    context 'with strict checking at error level' do
      let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures' }

      it 'deals with canonicalized resources correctly' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} device_provider wibble ensure=present #{default_type_values}")
        stdmatch = 'Error: /Device_provider\[wibble\]: Could not evaluate: device_provider\[wibble\]#get has not provided canonicalized values.\n'\
                   'Returned values:       \{:name=>"wibble", :ensure=>"present", :string=>"sample", :string_ro=>"fixed"\}\n'\
                   'Canonicalized values:  \{:name=>"wibble", :ensure=>"present", :string=>"changed", :string_ro=>"fixed"\}'
        expect(stdout_str).to match %r{#{stdmatch}}
        expect(status).to be_success
      end
    end

    context 'with strict checking at warning level' do
      let(:common_args) { '--verbose --trace --strict=warning --modulepath spec/fixtures' }

      it 'deals with canonicalized resources correctly' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} device_provider wibble ensure=present #{default_type_values}")
        stdmatch = 'Warning: device_provider\[wibble\]#get has not provided canonicalized values.\n'\
                   'Returned values:       \{:name=>"wibble", :ensure=>"present", :string=>"sample", :string_ro=>"fixed"\}\n'\
                   'Canonicalized values:  \{:name=>"wibble", :ensure=>"present", :string=>"changed", :string_ro=>"fixed"\}'
        expect(stdout_str).to match %r{#{stdmatch}}
        expect(status).to be_success
      end
    end

    context 'with strict checking turned off' do
      let(:common_args) { '--verbose --trace --strict=off --modulepath spec/fixtures' }

      it 'reads resources from the target system' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} device_provider")
        expected_values = 'device_provider { \'wibble\': \n\s+ensure => \'present\',\n\s+string => \'sample\',\n\#\s+string_ro => \'fixed\', # Read Only\n  string_param => \'default value\',\n}'
        expect(stdout_str.strip).to match %r{\A(DL is deprecated, please use Fiddle\n)?#{expected_values}\Z}
        expect(status).to eq 0
      end

      it 'deals with canonicalized resources correctly' do
        stdout_str, status = Open3.capture2e("puppet resource #{common_args} device_provider wibble ensure=present #{default_type_values}")
        stdmatch = 'Notice: /Device_provider\[wibble\]/string: string changed \'sample\' to \'changed\''
        expect(stdout_str).to match %r{#{stdmatch}}
        expect(status).to be_success
      end
    end
  end

  describe 'using `puppet device`' do
    let(:common_args) { super() + ' --target the_node' }
    let(:device_conf) { Tempfile.new('device.conf') }
    let(:device_conf_content) do
      <<DEVICE_CONF
[the_node]
type test_device
url  file:///etc/credentials.txt
DEVICE_CONF
    end

    before(:each) do
      device_conf.write(device_conf_content)
      device_conf.close
    end

    after(:each) do
      device_conf.unlink
    end

    context 'with no config specified' do
      it 'errors out' do
        stdout_str, _status = Open3.capture2e("puppet device #{common_args}")
        expect(stdout_str).to match %r{Target device / certificate.*not found}
      end
    end

    it 'applies a catalog successfully' do
      stdout_str, _status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path} --apply 'notify{\"foo\":}'")
      expect(stdout_str).to match %r{starting applying configuration to the_node at file:///etc/credentials.txt}
      expect(stdout_str).to match %r{defined 'message' as 'foo'}
      expect(stdout_str).not_to match %r{Error:}
    end

    it 'has the "foo" fact set to "bar"' do
      stdout_str, status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path} --apply 'if $facts[\"foo\"] != \"bar\" { fail(\"fact not found\") }'")
      expect(stdout_str).not_to match %r{Error:}
      expect(status).to eq 0
    end

    context 'with a device resource in the catalog' do
      it 'applies the catalog successfully' do
        stdout_str, _status = Open3.capture2e("puppet device #{common_args} --deviceconfig #{device_conf.path} --apply 'device_provider{\"foo\": "\
                                              'ensure => "present", boolean => true, integer => 15, float => 1.23, variant_pattern => "0x1234ABCD", '\
                                              'url => "http://www.google.com", boolean_param => false, integer_param => 99, float_param => 3.21, '\
                                              "ensure_param => \"present\", variant_pattern_param => \"9A2222ED\", url_param => \"http://www.puppet.com\"}'")
        expect(stdout_str).not_to match %r{Error:}
      end
    end
  end
end
