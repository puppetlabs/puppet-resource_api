require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_custom_insync_hidden_property type using the Resource API.
class Puppet::Provider::TestCustomInsyncHiddenProperty::TestCustomInsyncHiddenProperty
  def get(_context)
    [
      {
        name: 'example'
      }
    ]
  end

  def set(context, changes)
    changes.each do |_name, is_and_should|
      context.notice("Setting with #{is_and_should[:should].inspect}")
    end
  end

  def insync?(context, name, _property_name, is_hash, should_hash)
    context.notice("Checking whether #{name} is out of sync")

    return true unless should_hash[:force]
    context.notice("Out of sync!")
    false
  end
end
