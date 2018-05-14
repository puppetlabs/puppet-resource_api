require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'test_simple_get_filter',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage ...
    EOS
  features: ['simple_get_filter'],
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
    test_string: {
      type:      'Optional[String]',
      desc:      'Used for testing our expected outcomes',
    },
  },
)
