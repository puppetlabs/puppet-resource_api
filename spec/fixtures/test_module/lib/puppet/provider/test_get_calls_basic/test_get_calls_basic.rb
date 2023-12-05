# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'

# Implementation for the test_get_calls_basic type using the Resource API.
class Puppet::Provider::TestGetCallsBasic::TestGetCallsBasic < Puppet::ResourceApi::SimpleProvider
  def get(context)
    @count ||= 0
    @count += 1
    context.notice("Provider get called #{@count} times")
    [
      {
        name: 'foo',
        ensure: 'present',
        prop: 'fooprop',
      },
      {
        name: 'bar',
        ensure: 'present',
        prop: 'barprop',
      },
    ]
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end
end
