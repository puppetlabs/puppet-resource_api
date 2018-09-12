require 'puppet/resource_api/simple_provider'

# Implementation for the test_sensitive type using the Resource API.
class Puppet::Provider::TestSensitive::TestSensitive < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    [
      {
        name: 'foo',
        ensure: 'present',
        secret: Puppet::Pops::Types::PSensitiveType::Sensitive.new('foosecret')
      },
      {
        name: 'bar',
        ensure: 'present',
        secret: Puppet::Pops::Types::PSensitiveType::Sensitive.new('barsecret')
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
