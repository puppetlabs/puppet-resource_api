require 'puppet/resource_api/base_context'
require 'puppet/util/logging'

class Puppet::ResourceApi::PuppetContext < Puppet::ResourceApi::BaseContext
  def log_exception(exception, message: 'Error encountered', trace: false)
    self.class.logging_proxy.log_exception(exception, message, trace: trace)
  end

  protected

  def send_log(level, message)
    Puppet::Util::Log.create(level: level, message: message)
  end

  # Avoid including Puppet::Util::Logging into the main class to avoid the namespace clashes
  class LoggingProxy
    include Puppet::Util::Logging
  end

  class << self
    def logging_proxy
      @logging_proxy ||= LoggingProxy.new
    end
  end
end
