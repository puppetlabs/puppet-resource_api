# frozen_string_literal: true

require 'open3'
require 'puppet/version'
require 'spec_helper'
require 'tempfile'

RSpec.describe 'exercising a type with device-specific providers' do
  let(:common_args) { '--verbose --trace --strict=error --modulepath spec/fixtures' }

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    FileUtils.mkdir_p(File.expand_path('~/.puppetlabs/opt/puppet/cache/devices/some_node/state'))
    FileUtils.mkdir_p(File.expand_path('~/.puppetlabs/opt/puppet/cache/devices/other_node/state'))
  end

  describe 'using `puppet device`' do
    let(:common_args) { super() + " --deviceconfig #{device_conf.path} --target some_node --target other_node" }
    let(:device_conf) { Tempfile.new('device.conf') }
    let(:device_conf_content) do
      <<~DEVICE_CONF
        [some_node]
        type some_device
        url  file:///etc/credentials.txt
        [other_node]
        type other_device
        url  file:///etc/credentials.txt
      DEVICE_CONF
    end

    def is_device_apply_supported?
      Gem::Version.new(Puppet::PUPPETVERSION) >= Gem::Version.new('5.3.6') && Gem::Version.new(Puppet::PUPPETVERSION) != Gem::Version.new('5.4.0')
    end

    before do
      skip "No device --apply in puppet before v5.3.6 nor in v5.4.0 (v#{Puppet::PUPPETVERSION} is installed)" unless is_device_apply_supported?
      device_conf.write(device_conf_content)
      device_conf.close
    end

    after do
      device_conf.unlink
    end

    it 'applies a catalog successfully' do
      pending "can't really test this without a puppetserver; when initially implementing this, it was tested using a hacked `puppet device` command allowing multiple --target params"

      # diff --git a/lib/puppet/application/device.rb b/lib/puppet/application/device.rb
      # index 5e7a5cd473..2d39527b47 100644
      # --- a/lib/puppet/application/device.rb
      # +++ b/lib/puppet/application/device.rb
      # @@ -70,7 +70,8 @@ class Puppet::Application::Device < Puppet::Application
      #    end

      #    option("--target DEVICE", "-t") do |arg|
      # -    options[:target] = arg.to_s
      # +    options[:target] ||= []
      # +    options[:target] << arg.to_s
      #    end

      #    def summary
      # @@ -232,7 +233,7 @@ Licensed under the Apache 2.0 License
      #        require 'puppet/util/network_device/config'
      #        devices = Puppet::Util::NetworkDevice::Config.devices.dup
      #        if options[:target]
      # -        devices.select! { |key, value| key == options[:target] }
      # +        devices.select! { |key, value| options[:target].include? key }
      #        end
      #        if devices.empty?
      #          if options[:target]

      # david@davids:~/git/puppet-resource_api$ bundle exec puppet device --verbose --trace --strict=error --modulepath spec/fixtures \
      #       --target some_node --target other_node --resource multi_device multi_device multi_device
      # ["multi_device", "multi_device", "multi_device"]
      # Info: retrieving resource: multi_device from some_node at file:///etc/credentials.txt
      # multi_device { 'multi_device':
      #   ensure => 'absent',
      # }
      # ["multi_device"]
      # Info: retrieving resource: multi_device from other_node at file:///etc/credentials.txt

      # david@davids:~/git/puppet-resource_api$

      Tempfile.create('apply_success') do |f|
        f.write 'multi_device { "foo": }'
        f.close

        stdout_str, _status = Open3.capture2e("puppet device #{common_args} --apply #{f.path}")
        expect(stdout_str).to match(/Compiled catalog for some_node/)
        expect(stdout_str).to match(/Compiled catalog for other_node/)
        expect(stdout_str).not_to match(/Error:/)
      end
    end
  end
end
