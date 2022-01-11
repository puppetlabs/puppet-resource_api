require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'test_optional_ensure',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage ...
    EOS
  features: [],
  attributes:   {
    ensure:      {
      type:    'Optional[Enum[present, absent]]',
      desc:    'Whether this resource should be present or absent on the target system.',
    },
    namevar:        {
      type:      'String',
      desc:      'The name of the resource you want to manage.',
      behaviour: :namevar,
    },
    prop: {
      type: 'String',
      desc: 'A property',
    }
  },
)
