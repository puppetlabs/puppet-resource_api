require 'puppet/resource_api'

Puppet::ResourceApi.register_transport(
  name: 'test_device', # points at class Puppet::Transport::TestDevice
  desc: 'Connects to a device',
  connection_info: {
  },
)
