require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'test_custom_insync_hidden_property',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage ...
    EOS
  features: ['custom_insync'],
  attributes:   {
    name:        {
      type:      'String',
      desc:      'The name of the resource you want to manage.',
      behaviour: :namevar,
    },
    force: {
      type:      'Boolean',
      desc:      'If true, the resource will be treated as not being insync.',
      behaviour: :parameter,
      default:   false,
    },
  },
)
