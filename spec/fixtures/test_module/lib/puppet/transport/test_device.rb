module Puppet::Transport
# a transport for a test_device
class TestDevice
  def initialize(_context, connection_info);
    puts connection_info
  end

  def facts(_context)
    { 'foo' => 'bar' }
  end

  def verify(_context)
    return true
  end

  def close(_context)
    return
  end
end

end
