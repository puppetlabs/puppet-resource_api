require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'test_validation',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage ...
    EOS
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
    prop:        {
      type:      'Integer',
      desc:      'A mandatory property, that MUST NOT be validated on deleting.',
    },
    param:       {
      type:      'Integer',
      desc:      'A mandatory parameter, that MUST be validated on deleting.',
      behaviour: :parameter,
    },
    prop_ro:        {
      type:      'Integer',
      desc:      'A property that cannot be set by a catalog',
      behaviour:  :read_only
    },
  },
)
