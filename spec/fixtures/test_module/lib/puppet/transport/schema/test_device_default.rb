require 'puppet/resource_api'

Puppet::ResourceApi.register_transport(
  name: 'test_device_default', # points at class Puppet::Transport::TestDeviceDefault
  desc: 'Connects to a device',
  connection_info: {
    username:        {
      type:      'String',
      desc:      'The name of the resource you want to manage.',
    },
    default_string: {
      type:      'String',
      desc:      'A string with a default.',
      default:   'default_value',
    },
    optional_default: {
      type:      'Optional[String]',
      desc:      'An optional string with a default.',
      default:   'another_default_value',
    },
    array_default: {
      type:      'Optional[Array[String]]',
      desc:      'An array of defaults.',
      default:   ['a', 'b']
    },
  },
)
