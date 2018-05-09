require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the title_provider type using the Resource API.
class Puppet::Provider::MultipleNamevar::MultipleNamevar < Puppet::ResourceApi::SimpleProvider

  def get(_context)
    [
        { package: 'php', manager: 'yum', ensure: 'present', },
        { package: 'php', manager: 'gem', ensure: 'present', },
        { package: 'mysql', manager: 'yum', ensure: 'present', },
        { package: 'mysql', manager: 'gem', ensure: 'present', },
        { package: 'foo', manager: 'bar', ensure: 'present', },
        { package: 'bar', manager: 'foo', ensure: 'present', },
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
