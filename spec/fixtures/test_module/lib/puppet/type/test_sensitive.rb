require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'test_sensitive',
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
    secret: {
      type:      'Sensitive[String]',
      desc:      'A secret to protect.',
    },
    optional_secret: {
      type:      'Optional[Sensitive[String]]',
      desc:      'An optional secret to protect.',
    },
    array_secret: {
      type:      'Array[Sensitive[String]]',
      desc:      'An array secret to protect.',
    },
  },
)
