require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'device_provider',
  docs: 'A example/test provider for device support',
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this apt key should be present or absent on the target system.',
      default: 'present',
    },
    name:        {
      type:      'String',
      desc:      'The name of the resource.',
      behaviour: :namevar,
    },
    attribute:     {
      type:      'String',
      desc:      'An attribute.',
    },
    parameter:    {
      type: 'String',
      desc: 'A parameter',
      behaviour: :parameter,
    },
  },
  features: ['remote_resource'],
)
