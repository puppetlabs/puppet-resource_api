require 'puppet/resource_api/base_context'
require 'puppet/util/logging'

class Puppet::ResourceApi::PuppetContext < Puppet::ResourceApi::BaseContext
  protected

  def send_log(level, message)
    Puppet::Util::Logging.send(level, message)
  end
end
