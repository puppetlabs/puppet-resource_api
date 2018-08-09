require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'test_bool',
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
    test_bool:   {
      type:      'Boolean',
      desc:      'A boolean property for testing.',
      default:   false,
    },
    test_bool_param: {
      type:      'Boolean',
      desc:      'A boolean parameter for testing.',
      behaviour: :parameter,
      default:   false,
    },
    variant_bool: {
      type:       'Variant[String, Boolean]',
      desc:       'A boolean variant atribute',
      default:    false,
    },
    optional_bool: {
      type:       'Optional[Boolean]',
      desc:       'An optional boolean attribute',
    },
  },
)
