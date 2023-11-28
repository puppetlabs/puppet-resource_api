# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'

# Implementation for the test_get_calls_sgf type using the Resource API.
class Puppet::Provider::TestGetCallsSgf::TestGetCallsSgf < Puppet::ResourceApi::SimpleProvider
  def get(context, names = nil)
    @count ||= 0
    @count += 1
    context.notice("Provider get called #{@count} times with names=#{names}")
    data = [
      {
        name: 'foo',
        ensure: 'present',
      },
      {
        name: 'bar',
        ensure: 'present',
      },
    ]
    if names.nil?
      data
    else
      data.select { |r| names.include?(r[:name]) }
    end
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
