require 'puppet/resource_api/base_logger'
require 'puppet/util/logging'

class Puppet::ResourceApi::PuppetLogger < Puppet::ResourceApi::BaseLogger
  def initialize(typename, target = $stderr)
    super(typename)
    @target = target
  end

  protected
  def send_log(level, message)
    Puppet::Util::Logging.send_method(method, message)
  end
end