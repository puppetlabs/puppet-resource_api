# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'test_get_calls_sgf',
  docs: <<-EOS,
@summary a test_get_calls_sgf type
@example
test_get_calls_sgf { 'foo':
  ensure => 'present',
}

This type provides Puppet with the capabilities to manage ...

If your type uses autorequires, please document as shown below, else delete
these lines.
**Autorequires**:
* `Package[foo]`
EOS
  features: ['simple_get_filter'],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'The name of the resource you want to manage.',
      behaviour: :namevar,
    },
    prop: {
      type: 'Optional[String]',
      desc: 'A property to manage.',
    },
  },
)
