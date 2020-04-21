require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'test_array',
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
    some_array:  {
      type: 'Array[String]',
      desc: 'An array aiding array attestation',
    },
    variant_array: {
      type: 'Variant[Array[String], String]',
      desc: 'an array, or a string',
    },
    array_of_arrays: {
      type: 'Array[Array[String]]',
      desc: 'an array of arrays',
    },
    array_from_hell: {
      type: 'Array[Variant[Array[String], String]]',
      desc: 'an array of weird things',
    },
    optional_string_array: {
      type: 'Optional[Array[String]]',
      desc: 'An optional attribute to exercise Array handling.',
    },
    untyped: {
      type: 'Optional[Any]',
      desc: 'Testing array handling in `Any` typed properties.',
    },
  },
)
