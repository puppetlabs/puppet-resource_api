require 'puppet/resource_api/base_logger'
require 'puppet/util/logging'

class Puppet::ResourceApi::PuppetLogger < Puppet::ResourceApi::BaseLogger
  protected

  def send_log(level, message)
    Puppet::Util::Logging.send(level, message)
  end
end
