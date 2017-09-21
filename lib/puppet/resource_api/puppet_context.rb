require 'puppet/resource_api/base_context'
require 'puppet/util/logging'

class Puppet::ResourceApi::PuppetContext < Puppet::ResourceApi::BaseContext
  # declare a separate class to encapsulate Puppet's logging facilities
  class PuppetLogger
    extend Puppet::Util::Logging
  end

  protected

  def send_log(level, message)
    PuppetLogger.send_log(level, message)
  end
end
