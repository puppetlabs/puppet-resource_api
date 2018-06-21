require 'puppet/resource_api/base_context'
require 'puppet/util/logging'

class Puppet::ResourceApi::PuppetContext < Puppet::ResourceApi::BaseContext
  def log_exception(exception, message: 'Error encountered', trace: false)
    super(exception, message: message, trace: trace || Puppet[:trace])
  end

  protected

  def send_log(level, message)
    Puppet::Util::Log.create(level: level, message: message)
  end
end
