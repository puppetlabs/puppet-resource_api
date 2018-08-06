require 'spec_helper'
require 'tempfile'

RSpec.describe 'a provider using booleans' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures --detailed-exitcodes' }

  # rubocop:disable RSpec/InstanceVariable
  describe 'using `puppet apply`' do
    before(:each) do
      @stdout_str, @status = Open3.capture2e("puppet apply #{common_args} -e \"#{manifest.delete("\n").squeeze(' ')}\"")
    end

    context 'when no changes are made' do
      let(:manifest) do
        <<DOC
        test_bool {
          foo: test_bool=>true, test_bool_param=>true, variant_bool=>true, optional_bool=>true;
          bar: test_bool=>false, test_bool_param=>false, variant_bool=>false, optional_bool=>false;
          wibble: ensure=>'present';
        }
DOC
      end

      it 'applies a catalog with no changes' do
        expect(@stdout_str).not_to match %r{Updating 'foo'}
        expect(@stdout_str).not_to match %r{Updating 'bar'}
        expect(@stdout_str).to match %r{Updating 'wibble' with \{:name=>"wibble", :ensure=>"present", :test_bool=>false, :variant_bool=>false, :optional_bool=>false, :test_bool_param=>false\}}
        expect(@stdout_str).to match %r{Test_bool\[wibble\]/test_bool: test_bool changed '?'? to 'false'}
        expect(@stdout_str).to match %r{Test_bool\[wibble\]/variant_bool: variant_bool changed '?'? to 'false'}
        expect(@stdout_str).to match %r{Test_bool\[wibble\]/optional_bool: optional_bool changed '?'? to 'false'}
        expect(@stdout_str).not_to match %r{Error:}
        expect(@status.exitstatus).to eq 2
      end
    end

    context 'when changes are made' do
      let(:manifest) do
        <<DOC
        test_bool {
          foo: test_bool=>false, test_bool_param=>false, variant_bool=>false, optional_bool=>false;
          bar: test_bool=>true, test_bool_param=>true, variant_bool=>true, optional_bool=>true;
          wibble: ensure=>'present', test_bool=>true, test_bool_param=>true, variant_bool=>true, optional_bool=>true
        }
DOC
      end

      it 'applies a catalog with bool changes' do
        expect(@stdout_str).to match %r{Test_bool\[foo\]/test_bool: test_bool changed (true|'true') to 'false'}
        expect(@stdout_str).to match %r{Test_bool\[bar\]/test_bool: test_bool changed (false|'false') to 'true'}
        expect(@stdout_str).to match %r{Updating 'foo' with \{:name=>"foo", :test_bool=>false, :variant_bool=>false, :optional_bool=>false, :test_bool_param=>false, :ensure=>"present"\}}
        expect(@stdout_str).to match %r{Updating 'bar' with \{:name=>"bar", :test_bool=>true, :variant_bool=>true, :optional_bool=>true, :test_bool_param=>true, :ensure=>"present"\}}
        expect(@stdout_str).to match %r{Test_bool\[wibble\]/test_bool: test_bool changed '?'? to 'true'}
        expect(@stdout_str).to match %r{Test_bool\[wibble\]/variant_bool: variant_bool changed '?'? to 'true'}
        expect(@stdout_str).to match %r{Test_bool\[wibble\]/optional_bool: optional_bool changed '?'? to 'true'}
        expect(@stdout_str).to match %r{Updating 'wibble' with \{:name=>"wibble", :ensure=>"present", :test_bool=>true, :variant_bool=>true, :optional_bool=>true, :test_bool_param=>true\}}
        expect(@stdout_str).not_to match %r{Error:}
        expect(@status.exitstatus).to eq 2
      end
    end
  end
  # rubocop:enable RSpec/InstanceVariable
end
