require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'test_custom_insync',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage ...
    EOS
  features: ['custom_insync'],
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
    case_sensitive_string: {
      type: 'Optional[String]',
      desc: 'A string which must be case sensitive',
    },
    case_insensitive_string: {
      type: 'Optional[String]',
      desc: 'A string which need not be case sensitive',
    },
    some_array:  {
      type: 'Optional[Array[String]]',
      desc: 'An array aiding array attestation',
    },
    force: {
      type:      'Boolean',
      desc:      'If true, the specified array is inclusive and must match the existing state exactly.',
      behaviour: :parameter,
      default:   false,
    },
    version:  {
      type: 'String',
      desc: 'A version string which may be prepended with a version matcher like "<=" or "~".',
      default: '',
    },
    minimum_version:  {
      type: 'Optional[String]',
      desc: 'A version string which current state must not be lower than',
      behaviour: :parameter,
    },
    maximum_version:  {
      type: 'Optional[String]',
      desc: 'A version string which current state must not be higher than',
      behaviour: :parameter,
    },
  },
)
