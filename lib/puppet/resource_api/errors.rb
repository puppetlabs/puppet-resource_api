# This error is thrown when a Command cannot find the specified command
class Puppet::ResourceApi::CommandNotFoundError < StandardError
end

# This error is thrown when a Command returned a non-zero exit code
class Puppet::ResourceApi::CommandExecutionError < StandardError
end
