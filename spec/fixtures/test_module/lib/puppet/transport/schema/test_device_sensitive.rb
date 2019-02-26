require 'puppet/resource_api'

Puppet::ResourceApi.register_transport(
  name: 'test_device_sensitive', # points at class Puppet::Transport::TestDevice
  desc: 'Connects to a device',
  connection_info: {
    username:        {
      type:      'String',
      desc:      'The name of the resource you want to manage.',
    },
    secret_string: {
      type:      'String',
      desc:      'A secret to protect.',
      sensitive:  true,
    },
    optional_secret: {
      type:      'Optional[String]',
      desc:      'An optional secret to protect.',
      sensitive:  true,
    },
    array_secret: {
      type:      'Optional[Array[String]]',
      desc:      'An array secret to protect.',
      sensitive:  true,
    },
    variant_secret: {
      type:      'Optional[Variant[Array[String], Integer]]',
      desc:      'An array secret to protect.',
      sensitive:  true,
    },
  },
)
