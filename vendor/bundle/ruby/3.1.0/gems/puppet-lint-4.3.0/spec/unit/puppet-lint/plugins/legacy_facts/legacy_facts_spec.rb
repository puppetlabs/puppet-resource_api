require 'spec_helper'

describe 'legacy_facts' do
  context 'with fix disabled' do
    context "fact variable using modern $facts['os']['family'] hash" do
      let(:code) { "$facts['os']['family']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context "fact variable using modern $facts['ssh']['rsa']['key'] hash" do
      let(:code) { "$facts['ssh']['rsa']['key']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'fact variable using legacy $osfamily' do
      let(:code) { '$osfamily' }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context "fact variable using legacy $facts['osfamily']" do
      let(:code) { "$facts['osfamily']" }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'fact variable using legacy $::osfamily' do
      let(:code) { '$::osfamily' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'fact variable using legacy $::blockdevice_sda_model' do
      let(:code) { '$::blockdevice_sda_model' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context "fact variable using legacy $facts['ipaddress6_em2']" do
      let(:code) { "$facts['ipaddress6_em2']" }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'fact variable using legacy $::zone_foobar_uuid' do
      let(:code) { '$::zone_foobar_uuid' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'fact variable using legacy $::processor314' do
      let(:code) { '$::processor314' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'fact variable using legacy $::sp_l3_cache' do
      let(:code) { '$::sp_l3_cache' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'fact variable using legacy $::sshrsakey' do
      let(:code) { '$::sshrsakey' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'fact variable in interpolated string "${::osfamily}"' do
      let(:code) { '"start ${::osfamily} end"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'fact variable using legacy variable in double quotes "$::osfamily"' do
      let(:code) { '"$::osfamily"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'fact variable using legacy facts hash variable in interpolation' do
      let(:code) { %("${facts['osfamily']}") }

      it 'detects a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'top scoped fact variable using legacy facts hash variable in interpolation' do
      let(:code) { "$::facts['osfamily']" }

      it 'detects a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'top scoped fact variable using unquoted legacy facts hash variable in interpolation' do
      let(:code) { '$::facts[osfamily]' }

      it 'detects a single problem' do
        expect(problems.size).to eq(1)
      end
    end

    context 'YAML file processing' do
      before(:each) do
        allow(File).to receive(:extname).and_return('.yaml')
      end

      context 'with YAML string containing legacy fact' do
        let(:code) { 'some_key: "%{::osfamily}"' }

        it 'detects a single problem' do
          expect(problems.size).to eq(1)
        end
      end

      context 'with YAML string not containing legacy fact' do
        let(:code) { 'some_key: "%{facts.os.name}"' }

        it 'does not detect any problems' do
          expect(problems).to be_empty
        end
      end

      context 'with YAML nested structure containing legacy fact' do
        let(:code) { "nested:\n  value: \"%{::architecture}\"" }

        it 'detects a single problem' do
          expect(problems.size).to eq(1)
        end
      end

      context 'with YAML array containing legacy facts' do
        let(:code) do
          [
            'array:',
            '  - "%{::processor0}"',
            '  - "%{::ipaddress_eth0}"',
          ].join("\n")
        end

        it 'detects multiple problems' do
          expect(problems.size).to eq(2)
        end
      end

      context 'with YAML alias containing legacy fact' do
        let(:code) do
          [
            'template: &template',
            '  fact: "%{::osfamily}"',
            'instance:',
            '  <<: *template',
          ].join("\n")
        end

        it 'detects multiple instances' do
          expect(problems.size).to eq(2)
        end
      end
    end
  end

  context 'with fix enabled' do
    before(:each) do
      PuppetLint.configuration.fix = true
    end

    after(:each) do
      PuppetLint.configuration.fix = false
    end

    context "fact variable using modern $facts['os']['family'] hash" do
      let(:code) { "$facts['os']['family']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context "fact variable using modern $facts['ssh']['rsa']['key'] hash" do
      let(:code) { "$facts['ssh']['rsa']['key']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'fact variable using legacy $osfamily' do
      let(:code) { '$osfamily' }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context "fact variable using legacy $facts['osfamily']" do
      let(:code) { "$facts['osfamily']" }
      let(:msg) { "legacy fact 'osfamily'" }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'fixes the problem' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("$facts['os']['family']")
      end
    end

    context 'fact variable using top scope $::facts hash' do
      let(:code) { "$::facts['os']['family']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context "fact variable using legacy top scope $::facts['osfamily']" do
      let(:code) { "$::facts['osfamily']" }
      let(:msg) { "legacy fact 'osfamily'" }

      it 'only detects a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'fixes the problem' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("$facts['os']['family']")
      end
    end

    context 'fact variable using legacy $::osfamily' do
      let(:code) { '$::osfamily' }
      let(:msg) { "legacy fact 'osfamily'" }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'fixes the problem' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("$facts['os']['family']")
      end
    end

    context 'fact variable using legacy $::sshrsakey' do
      let(:code) { '$::sshrsakey' }
      let(:msg) { "legacy fact 'sshrsakey'" }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'fixes the problem' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("$facts['ssh']['rsa']['key']")
      end
    end

    context 'fact variable using legacy $::memoryfree_mb' do
      let(:code) { '$::memoryfree_mb' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'continues to use the legacy fact' do
        expect(manifest).to eq('$::memoryfree_mb')
      end
    end

    context 'fact variable using legacy $::blockdevice_sda_model' do
      let(:code) { '$::blockdevice_sda_model' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("$facts['disks']['sda']['model']")
      end
    end

    context "fact variable using legacy $facts['ipaddress6_em2']" do
      let(:code) { "$facts['ipaddress6_em2']" }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("$facts['networking']['interfaces']['em2']['ip6']")
      end
    end

    context 'fact variable using legacy $::zone_foobar_uuid' do
      let(:code) { '$::zone_foobar_uuid' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("$facts['solaris_zones']['zones']['foobar']['uuid']")
      end
    end

    context 'fact variable using legacy $::processor314' do
      let(:code) { '$::processor314' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("$facts['processors']['models'][314]")
      end
    end

    context 'fact variable using legacy $::sp_l3_cache' do
      let(:code) { '$::sp_l3_cache' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("$facts['system_profiler']['l3_cache']")
      end
    end

    context 'fact variable using legacy $::sshrsakey' do
      let(:code) { '$::sshrsakey' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("$facts['ssh']['rsa']['key']")
      end
    end

    context 'fact variable in interpolated string "${::osfamily}"' do
      let(:code) { '"start ${::osfamily} end"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq('"start '"${facts['os']['family']}"' end"') # rubocop:disable Lint/ImplicitStringConcatenation
      end
    end

    context 'fact variable using legacy variable in double quotes "$::osfamily"' do
      let(:code) { '"$::osfamily"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"$facts['os']['family']\"")
      end
    end

    context 'fact variable using legacy variable in double quotes "$::gid"' do
      let(:code) { '"$::gid"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"$facts['identity']['group']\"")
      end
    end

    context 'fact variable using legacy variable in double quotes "$::id"' do
      let(:code) { '"$::id"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"$facts['identity']['user']\"")
      end
    end

    context 'fact variable using legacy variable in double quotes "$::lsbdistcodename"' do
      let(:code) { '"$::lsbdistcodename"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"$facts['os']['distro']['codename']\"")
      end
    end

    context 'fact variable using legacy variable in double quotes "$::lsbdistdescription"' do
      let(:code) { '"$::lsbdistdescription"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"$facts['os']['distro']['description']\"")
      end
    end

    context 'fact variable using legacy variable in double quotes "$::lsbdistid"' do
      let(:code) { '"$::lsbdistid"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"$facts['os']['distro']['id']\"")
      end
    end

    context 'fact variable using legacy variable in double quotes "$::lsbdistrelease"' do
      let(:code) { '"$::lsbdistrelease"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"$facts['os']['distro']['release']['full']\"")
      end
    end

    context 'fact variable using legacy variable in double quotes "$::lsbmajdistrelease"' do
      let(:code) { '"$::lsbmajdistrelease"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"$facts['os']['distro']['release']['major']\"")
      end
    end

    context 'fact variable using legacy variable in double quotes "$::lsbminordistrelease"' do
      let(:code) { '"$::lsbminordistrelease"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"$facts['os']['distro']['release']['minor']\"")
      end
    end

    context 'fact variable using legacy variable in double quotes "$::lsbrelease"' do
      let(:code) { '"$::lsbrelease"' }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"$facts['os']['distro']['release']['specification']\"")
      end
    end

    context "fact variable using facts hash in double quotes \"$facts['lsbrelease']\"" do
      let(:code) { "\"${facts['lsbrelease']}\"" }

      it 'only detect a single problem' do
        expect(problems.size).to eq(1)
      end

      it 'uses the facts hash' do
        expect(manifest).to eq("\"${facts['os']['distro']['release']['specification']}\"")
      end
    end

    context 'variable ending in the word fact' do
      let(:code) { "$interface_facts['netmask']" }

      it 'does not detect any problems' do
        expect(problems.size).to eq(0)
      end
    end
  end
end
