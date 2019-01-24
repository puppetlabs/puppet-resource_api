require 'puppet/resource_api/base_context'

# Implement Resource API Conext to log through an IO object, defaulting to `$stderr`.
# There is no access to a device here.
class Puppet::ResourceApi::IOContext < Puppet::ResourceApi::BaseContext
  def initialize(definition, target = $stderr)
    super(definition)
    @target = target
  end

  protected

  def send_log(level, message)
    @target.puts "#{level}: #{message}"
  end
end
