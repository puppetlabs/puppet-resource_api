require 'puppet/resource_api/base_context'

class Puppet::ResourceApi::IOContext < Puppet::ResourceApi::BaseContext
  def initialize(typename, target = $stderr)
    super(typename)
    @target = target
  end

  protected

  def send_log(level, message)
    @target.puts "#{level}: #{message}"
  end
end
