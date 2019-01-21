module Puppet::Transport
# a transport for a test_device
class TestDevice
  def initialize(connection_info);
    puts connection_info
  end

  def facts
    { 'foo' => 'bar' }
  end

  def verify
    return true
  end

  def close
    return
  end
end

end
