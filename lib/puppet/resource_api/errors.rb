
module Puppet::ResourceApi
  # This error is thrown when a Command cannot find the specified command
  class CommandNotFoundError < StandardError
  end

  # This error is thrown when a Command returned a non-zero exit code
  class CommandExecutionError < StandardError
  end
end
