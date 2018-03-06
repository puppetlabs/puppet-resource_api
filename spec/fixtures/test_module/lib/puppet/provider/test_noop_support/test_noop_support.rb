require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_noop_support type using the Resource API.
class Puppet::Provider::TestNoopSupport::TestNoopSupport
  def get(_context)
    [
      {
        name: 'foo',
        ensure: :present,
      },
      {
        name: 'bar',
        ensure: :present,
      },
    ]
  end

  def set(context, changes, noop: false)
    context.notice("noop: #{noop}")
    context.notice("inspect: #{changes.inspect}")
  end
end
