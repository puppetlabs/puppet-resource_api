# The harness to wrap a Resource Implementation into a usable class
#
# The Resource Implementation is wrapped in a BasicObject to eliminate any
# namespace clashes, while the Harness is a real ruby Object that is easier
# to handle, and provides more functionality to work with the implementation.
class Puppet::ResourceApi::Harness
  def initialize(&block)
    @provider = BasicObject.new
    @provider.instance_eval(&block)

    raise Puppet::DevError, 'provider requires a get() method' unless method? :get
    raise Puppet::DevError, 'provider requires a set() method' unless method? :set
  end

  def get(*args)
    @provider.get(*args)
  end

  def set(*args)
    @provider.set(*args)
  end

  def canonicalize?
    method? :canonicalize
  end

  def canonicalize(*args)
    @provider.canonicalize(*args)
  end

  private

  def method?(method_name)
    Kernel.instance_method(:respond_to?).bind(@provider).call method_name
  end
end
