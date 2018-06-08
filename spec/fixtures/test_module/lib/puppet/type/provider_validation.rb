require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'provider_validation',
  docs: <<-DOC,
    This type provides Puppet with the capabilities to manage ...
  DOC
  attributes:   {
    name: {
      type: 'String',
      behaviour: :namevar,
      desc: 'the title'
    },
    string: {
      type: 'String',
      desc: 'a string parameter',
      default: 'default value'
    },
    boolean: {
      type: 'Boolean',
      desc: 'a boolean parameter'
    },
    integer: {
      type: 'Integer',
      desc: 'an integer parameter'
    },
    float: {
      type: 'Float',
      desc: 'a floating point parameter'
    },
    variant_pattern: {
      type: 'Variant[Pattern[/\A(0x)?[0-9a-fA-F]{8}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{16}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{40}\Z/]]',
      desc: 'a pattern parameter'
    },
    url: {
      type: 'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]',
      desc: 'a hkp or http(s) url parameter'
    },
    optional_string: {
      type: 'Optional[String]',
      desc: 'a optional string parameter'
    },
    optional_int: {
      type: 'Optional[Integer]',
      desc: 'a optional integer parameter'
    }
  },
)
