require 'puppet/util/network_device/simple/device'

module Puppet::Util::NetworkDevice::Test_device # rubocop:disable Style/ClassAndModuleCamelCase
  # A simple test device returning hardcoded facts
  class Device < Puppet::Util::NetworkDevice::Simple::Device
    def facts
      facts = { 'foo' => 'bar' }
      custom_facts = return_custom_facts
      custom_facts.each do |custom_fact|
        begin
          load custom_fact
          jim = Example_ResourceAPI_Fact
          bla = jim.add_fact(nil, facts)
        rescue => detail
          puts "Error loading/executing custom fact:#{custom_fact}"
          Puppet.log_exception(detail)
        end
      end
    facts
    end
  end
end
