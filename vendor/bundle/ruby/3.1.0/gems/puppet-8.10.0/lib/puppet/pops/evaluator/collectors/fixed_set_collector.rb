# frozen_string_literal: true

class Puppet::Pops::Evaluator::Collectors::FixedSetCollector < Puppet::Pops::Evaluator::Collectors::AbstractCollector
  # Creates a FixedSetCollector using the AbstractCollector constructor
  # to set the scope. It is not possible for a collection to have
  # overrides in this case, since we have a fixed set of resources that
  # can be different types.
  #
  # @param [Array] resources the fixed set of resources we want to realize
  def initialize(scope, resources)
    super(scope)
    @resources = resources.is_a?(Array) ? resources.dup : [resources]
  end

  # Collects a fixed set of resources and realizes them. Used
  # by the realize function
  def collect
    resolved = []
    result = @resources.each_with_object([]) do |ref, memo|
      res = @scope.findresource(ref.to_s)
      next unless res

      res.virtual = false
      memo << res
      resolved << ref
    end

    @resources -= resolved

    @scope.compiler.delete_collection(self) if @resources.empty?

    result
  end

  def unresolved_resources
    @resources
  end
end
