require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the title_provider type using the Resource API.
class Puppet::Provider::CompositeNamevar::CompositeNamevar < Puppet::ResourceApi::SimpleProvider
  def initialize
    @current_values ||= [
      { title: 'php-yum', package: 'php', manager: 'yum', ensure: 'present', value: 'a' },
      { title: 'php-gem', package: 'php', manager: 'gem', ensure: 'present', value: 'b' },
      { title: 'mysql-yum', package: 'mysql', manager: 'yum', ensure: 'present', value: 'c' },
      { title: 'mysql-gem', package: 'mysql', manager: 'gem', ensure: 'present', value: 'd' },
      { title: 'foo-bar', package: 'foo', manager: 'bar', ensure: 'present', value: 'e' },
      { title: 'bar-foo', package: 'bar', manager: 'foo', ensure: 'present', value: 'f' },
    ]
  end

  def get(_context)
    @current_values
  end

  def create(context, name, should)
    context.notice("Creating '#{name[:title]}' with #{should.inspect}")
    context.notice("namevar :package value `#{name[:package]}`")
    context.notice("namevar :manager value `#{name[:manager]}`")
  end

  def update(context, name, should)
    context.notice("Updating '#{name[:title]}' with #{should.inspect}")
    context.notice("namevar :package value `#{name[:package]}`")
    context.notice("namevar :manager value `#{name[:manager]}`")
  end

  def delete(context, name)
    context.notice("Deleting '#{name[:title]}'")
    context.notice("namevar :package value `#{name[:package]}`")
    context.notice("namevar :manager value `#{name[:manager]}`")
  end
end
