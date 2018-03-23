require 'puppet/resource_api/base_context'
require 'puppet/util/logging'

class Puppet::ResourceApi::PuppetContext < Puppet::ResourceApi::BaseContext
  protected

  def send_log(level, message)
    Puppet::Util::Log.create(level: level, message: message)
  end
end
