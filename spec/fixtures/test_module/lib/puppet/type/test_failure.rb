require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'test_failure',
  docs: <<-DOC,
      This type provides Puppet with the capabilities to manage ...
  DOC
  features: [],
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name:        {
      type:      'String',
      desc:      'The name of the resource you want to manage.',
      behaviour: :namevar,
    },
    failure:   {
      type:      'Boolean',
      desc:      'A boolean property for testing.',
      default:   false,
    },
  },
)
