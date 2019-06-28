require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'composite_namevar',
  docs: <<-DOC,
    This type provides Puppet with the capabilities to manage ...
  DOC
  features: [ 'simple_get_filter' ],
  title_patterns: [
    {
      pattern: %r{^(?<package>.*[^-])-(?<manager>.*)$},
      desc: 'Where the package and the manager are provided with a hyphen separator',
    },
    {
      pattern: %r{^(?<package>.*[^/])/(?<manager>.*)$},
      desc: 'Where the package and the manager are provided with a forward slash separator',
    },
    {
      pattern: %r{^(?<package>[a-z]*[^/])$},
      desc: 'Fallback pattern where only the package is provided',
    },
  ],
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
    value:     {
      type: 'Optional[String]',
      desc: 'An arbitrary string for debugging purposes',
    },
  },
)
