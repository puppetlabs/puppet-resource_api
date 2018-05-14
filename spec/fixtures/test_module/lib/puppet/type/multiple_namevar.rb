require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'multiple_namevar',
  docs: <<-EOS,
    This type provides Puppet with the capabilities to manage ...
  EOS
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    package:        {
      type:      'String',
      desc:      'The name of the file you want to manage.',
      behaviour: :namevar,
    },
    manager:        {
      type:      'String',
      desc:      'The directory containing the resource you want to manage.',
      behaviour: :namevar,
    },
  },
)
