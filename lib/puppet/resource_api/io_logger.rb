require 'puppet/resource_api/base_logger'

class Puppet::ResourceApi::IOLogger < Puppet::ResourceApi::BaseLogger
  def initialize(typename, target = $stderr)
    super(typename)
    @target = target
  end

  protected

  def send_log(level, message)
    @target.puts "#{level}: #{message}"
  end
end
